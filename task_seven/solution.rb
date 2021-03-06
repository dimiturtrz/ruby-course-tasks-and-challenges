class LazyMode
  class Date
    YEAR_DAYS = 30 * 12
    MONTH_DAYS = 30
    WEEK_DAYS = 7

    def initialize(start_date)
      @year, @month, @day = start_date.split("-")
    end

    def year
      @year
    end

    def month
      @month
    end

    def day
      @day
    end

    def to_s
      "#{@year}-#{@month}-#{@day}"
    end

    def match_date(other_date, period, match_type)
      difference = days_difference(other_date)
      difference %= period_frequency(period) if period
      case match_type
        when :weekly then difference.between?(0, WEEK_DAYS)
        when :daily then difference == 0
      end
    end

    def days_difference(other_date)
      days_difference = (other_date.year.to_i - year.to_i) * YEAR_DAYS
      days_difference += (other_date.month.to_i - month.to_i) * MONTH_DAYS
      days_difference += other_date.day.to_i - day.to_i
    end

    def period_frequency(period)
      n = period[1 .. -2].to_i
      n * case period[-1]
        when "m" then MONTH_DAYS
        when "w" then WEEK_DAYS
        when "d" then 1
      end
    end
  end

  class Note
    def initialize(header, file, *tags)
      @header = header
      @file = file
      @tags = tags.flatten
      @status = :topostpone
    end

    def header
      @header
    end

    def file_name
      @file.name
    end

    def body(new_body = nil)
      @body = new_body ? new_body : @body
    end

    def status(new_status = nil)
      @status = new_status ? new_status : @status
    end

    def tags
      @tags
    end

    def scheduled(new_date = nil)
      @date = new_date ? new_date : @date
    end

    def note(header, *tags, &initialization_block)
      @file.note header, *tags, &initialization_block
    end
  end

  def self.create_file(file_name, &initialization_block)
    file = File.new file_name
    file.instance_eval &initialization_block
    file
  end

  class File
    def initialize(file_name)
      @file_name = file_name
      @notes = []
    end

    def name
      @file_name
    end

    def notes
      @notes
    end

    def note(header, *tags, &initialization_block)
      @notes << Note.new(header, self, tags)
      @notes.last.instance_eval &initialization_block
    end

    def daily_agenda(date)
      create_agenda date, :daily
    end

    def weekly_agenda(date)
      create_agenda date, :weekly
    end

    def create_agenda(date, type)
      Agenda.new (@notes.select do |note|
        note_date = note.scheduled
        other_date = Date.new note_date[/\d{4}-\d{2}-\d{2}/]
        period = note_date[/\+\d[mdw]/]
        date.match_date other_date, period, type
      end), date, type
    end
  end

  class Agenda
    def initialize(notes, date, type)
      @notes = notes
      @type = type
      @date = date
      @notes.each{ |note| define_date_to_note note }
    end

    def define_date_to_note(note)
      date = determine_date note
      note.instance_eval do
	      @agenda_date = date
        def date
          @agenda_date
        end
      end
    end

    def determine_date(note)
      date = note.scheduled
      if date.length > 10
        return periodic_date(date)
      else
        return date
      end
    end

    def periodic_date(date_string)
      return @date unless @type == "weekly"
      date = Date.new date_string[/\d{4}-\d{2}-\d{2}/]
      period = date_string[/\+\d[mdw]/]
      weekly_periodic_date date, period
    end

    def weekly_periodic_date(date, period)
      difference = @date.days_difference(date) % @date.period_frequency(period)
      day = date.day.to_i + difference
      month = date.month.to_i + (day / 30)
      year = date.year.to_i + (month / 12)
      new_date = [year, month % 12, day % 30]
      new_date.map{ |time| time.to_s.rjust(2, '0')}.join("-")
    end

    def notes
      @notes
    end

    def where(tag: nil, text: /.*/, status: nil)
      notes = @notes.select do |note|
        note.header =~ text &&
        (note.tags.include? tag || ! tag) &&
        (note.status == status || ! status)
      end
      Agenda.new notes, @date, @type
    end
  end
end
