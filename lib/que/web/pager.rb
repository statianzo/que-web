class Que::Web::Pager
  attr_reader :current_page, :page_size, :page_count
  attr_accessor :total

  def initialize(page_no, page_size, total)
    @current_page = page_no > 1 ? page_no : 1
    @page_size = page_size
    @total = total

    @page_count = total > 0 ? (total / page_size.to_f).ceil : 1
  end

  def next_page
    @current_page < @page_count ? (@current_page + 1) : nil
  end

  def prev_page
    @current_page > 1 ? (@current_page - 1) : nil
  end

  def offset
    (@current_page - 1) * @page_size
  end
end
