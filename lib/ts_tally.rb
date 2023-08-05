require 'csv'
require 'time'

class TSTally
  def initialize(raw_csv, title='')
    @title = title
    @contents = create_objs(raw_csv)
  end

  def display
    day_tally, wk_tally = calc_tally(@contents)
    display_output(day_tally, wk_tally)
  end

  private

  def create_objs(raw_csv)
    # output for each row:
    #   { row[0][0]: row[x][0], row[0][1]: row[x][1], etc.  }
    headers = raw_csv[0]
    output = []
    raw_csv.each_with_index do |row, ridx|
      next if ridx == 0

      row_hash = {}
      (0...row.length).each { |cidx| row_hash[headers[cidx]] = row[cidx] }

      output << row_hash
    end
    output
  end

  def data_path
    File.expand_path('~/launchschool/', __dir__)
  end

  def get_filepath(file)
    File.join(data_path, file)
  end

  def calc_duration(obj)
    start_time =
      DateTime.strptime("#{obj['date']} #{obj['start']}", '%d-%b-%y %H:%M')
    end_time =
      DateTime.strptime("#{obj['date']} #{obj['end']}", '%d-%b-%y %H:%M')

    # result is in days - convert to hours
    ((end_time - start_time).to_f * 24).round(2)
  end

  def get_date(str)
    DateTime.strptime("#{str} 07:00", '%d-%b-%y %H:%M')
  end

  def week(date_str)
    date = get_date(date_str)
    # start each week on Sunday, cweek starts each week on Mon
    date.sunday? ? date.cweek + 1 : date.cweek
  end

  def display_output(day_tally, wk_tally)
    out = @title.empty? ? [] : ["  ===  #{@title}  ===  "]
    day_tally.each do |key, value|
      out << "#{week(key)} : #{key} : #{value.round(2)} hrs"
    end

    out << "=" * 30
    out << "     Weekly totals"
    wk_tally.each do |key, value|
      out << "#{key} : #{value.round(2)} hrs"
    end
    out.join("\n")
  end

  def tally_weeks(day_tally)
    tally_wk = Hash.new { 0 }
    day_tally.each do |date_str, value|
      wk = week(date_str)
      tally_wk[wk] += value.round(2)
    end
    tally_wk
  end

  def tally_days(contents)
    tally = Hash.new { 0 }
    contents.each do |obj|
      date = obj["date"]
      tally[date] += calc_duration(obj)
    end
    tally
  end

  def calc_tally(contents)
    day_tally = tally_days(contents)
    wk_tally = tally_weeks(day_tally)
    [day_tally, wk_tally]
  end
end
