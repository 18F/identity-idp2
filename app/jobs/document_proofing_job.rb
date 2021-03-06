class DocumentProofingJob < ApplicationJob
  include JobHelpers::FaradayHelper

  queue_as :default

  def perform(result_id:, encrypted_arguments:, trace_id:,
              liveness_checking_enabled:, analytics_data:)
    dcs = DocumentCaptureSession.find_by(result_id: result_id)
    user = dcs.user

    timer = JobHelpers::Timer.new
    decrypted_args = JSON.parse(
      Encryption::Encryptors::SessionEncryptor.new.decrypt(encrypted_arguments),
      symbolize_names: true,
    )[:document_arguments]

    encryption_key = Base64.decode64(decrypted_args[:encryption_key].to_s)
    front_image_iv = Base64.decode64(decrypted_args[:front_image_iv].to_s)
    back_image_iv = Base64.decode64(decrypted_args[:back_image_iv].to_s)
    selfie_image_iv = Base64.decode64(decrypted_args[:selfie_image_iv].to_s)
    front_image_url = decrypted_args[:front_image_url]
    back_image_url = decrypted_args[:back_image_url]
    selfie_image_url = decrypted_args[:selfie_image_url]

    front_image = decrypt_from_s3(
      timer: timer, name: :front, url: front_image_url, iv: front_image_iv, key: encryption_key,
    )
    back_image = decrypt_from_s3(
      timer: timer, name: :back, url: back_image_url, iv: back_image_iv, key: encryption_key,
    )
    selfie_image = decrypt_from_s3(
      timer: timer, name: :selfie, url: selfie_image_url, iv: selfie_image_iv, key: encryption_key,
    ) if liveness_checking_enabled

    proofer_result = timer.time('proof_documents') do
      with_retries(**faraday_retry_options) do
        doc_auth_client.post_images(
          front_image: front_image,
          back_image: back_image,
          selfie_image: selfie_image || '',
          liveness_checking_enabled: liveness_checking_enabled,
        )
      end
    end

    dcs.store_doc_auth_result(
      result: proofer_result.to_h, # pii_from_doc is excluded from to_h to stop accidental logging
      pii: proofer_result.pii_from_doc,
    )

    analytics = Analytics.new(user: user, request: nil, sp: dcs.issuer)

    remaining_attempts = Throttler::RemainingCount.call(
      user.id,
      :idv_acuant,
    )

    analytics.track_event(
      Analytics::IDV_DOC_AUTH_SUBMITTED_IMAGE_UPLOAD_VENDOR,
      proofer_result.to_h.merge(
        state: proofer_result.pii_from_doc[:state],
        async: true,
        remaining_attempts: remaining_attempts,
      ).merge(analytics_data),
    )
  ensure
    logger.info(
      {
        name: 'ProofDocument',
        trace_id: trace_id,
        success: proofer_result&.success?,
        timing: timer.results,
      }.to_json,
    )
  end

  private

  def doc_auth_client
    @doc_auth_client ||= DocAuthRouter.client
  end

  def encryption_helper
    @encryption_helper ||= JobHelpers::EncryptionHelper.new
  end

  def s3_helper
    @s3_helper ||= JobHelpers::S3Helper.new
  end

  def decrypt_from_s3(timer:, name:, url:, iv:, key:)
    encrypted_image = timer.time("download.#{name}") do
      if s3_helper.s3_url?(url)
        s3_helper.download(url)
      else
        build_faraday.get(url).body.b
      end
    end
    timer.time("decrypt.#{name}") do
      encryption_helper.decrypt(data: encrypted_image, iv: iv, key: key)
    end
  end
end
