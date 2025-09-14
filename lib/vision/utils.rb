# frozen_string_literal: true

module Vision
  module Utils
    module_function

    def dot_product(a, b)
      a.zip(b).map { |x, y| x * y }.sum
    end

    def l2_distance(a, b)
      Math.sqrt(a.zip(b).map { |x, y| (x - y) ** 2 }.sum)
    end

    def cosine_similarity(a, b)
      dot = dot_product(a, b)
      norm_a = Math.sqrt(a.map { |x| x * x }.sum)
      norm_b = Math.sqrt(b.map { |x| x * x }.sum)
      return 0.0 if norm_a.zero? || norm_b.zero?
      dot / (norm_a * norm_b)
    end
  end
end

