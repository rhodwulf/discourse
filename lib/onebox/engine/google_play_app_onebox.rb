module Onebox
  module Engine
    class GooglePlayAppOnebox
      include Engine
      include LayoutSupport
      include HTML

      matches_regexp Regexp.new("^http(?:s)?://play\\.(?:(?:\\w)+\\.)?(google)\\.com(?:/)?/store/apps/")

      private

      def data
        result = {
          link: link,
          title: raw.css(".document-title div").inner_text,
          developer: raw.css(".document-subtitle.primary").inner_text,
          image: raw.css(".cover-image").first["src"],
          description: raw.css(".text-body div").inner_text,
          price: raw.css(".price.buy meta[itemprop=price]").first["content"]
        }
        if result[:price].to_i <= 0 then
            result[:price] = "Free"
        end
        result
      end
    end
  end
end
