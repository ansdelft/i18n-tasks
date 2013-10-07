# coding: utf-8
require 'i18n/tasks/base_task'

module I18n
  module Tasks
    class Missing < BaseTask

      # get all the missing translations as list of missing keys as hashes with:
      #  {:locale, :key, :type, and optionally :base_value}
      #  :type — :blank, :missing, or :eq_base
      #  :base_value — translation value in base locale if one is present
      def find_keys
        # missing keys, i.e. key that are in the code but are not in the base locale data
        missing = keys_missing_base_value

        # present in base locale, but untranslated in another locale
        missing += (I18n.available_locales.map(&:to_s) - [base_locale]).map { |locale|
          keys_missing_translation(locale)
        }.flatten(1)

        # sort first by locale, then by type
        missing.sort! { |a, b| (l = a[:locale] <=> b[:locale]).zero? ? a[:type] <=> b[:type] : l }
        missing
      end

      private

      def keys_missing_translation(locale)
        trn = get_locale_data(locale)[locale]
        r   = []
        traverse base_locale_data do |key, base_value|
          value_in_locale = t(trn, key)
          if value_in_locale.blank? && !ignore_key?(key, :missing)
            r << {locale: locale, key: key, type: :blank, base_value: base_value}
          elsif value_in_locale == base_value && !ignore_key?(key, :eq_base, locale)
            r << {locale: locale, key: key, type: :eq_base, base_value: base_value}
          end
        end
        r
      end

      def keys_missing_base_value
        find_source_keys.reject { |key|
          key_has_value?(key, base_locale) || pattern_key?(key) || ignore_key?(key, :missing)
        }.map { |key| {locale: base_locale, type: :none, key: key} }
      end
    end
  end
end
