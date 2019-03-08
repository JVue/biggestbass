require_relative 'postgres'
require_relative 'log'
#require_relative '../secrets'

class BiggestBass
  def initialize
    @pg = PostGres.new
    @log = Log.new
  end

  def add_bb_user(name)
    @pg.db_insert_data('biggestbass', 'name', "\'#{name}\'")
  end

  def update_bb_field(user, column, value)
    @pg.update_table_field('biggestbass', column, value, 'name', user)
  end

  def paid_entry_fee(date, user, amount_paid)
    @pg.update_table_fields('biggestbass',"entry_fee_paid=\'#{amount_paid}\', entry_fee_paid_date=\'#{date}\'", 'name', user)
  end

  def update_bass_weight(date, user, fish_type, new_weight)
    case fish_type
    when 'largemouth_weight'
      @pg.update_table_fields('biggestbass',"largemouth_weight=\'#{new_weight}\', largemouth_weight_date=\'#{date}\'", 'name', user)
    when 'smallmouth_weight'
      @pg.update_table_fields('biggestbass',"smallmouth_weight=\'#{new_weight}\', smallmouth_weight_date=\'#{date}\'", 'name', user)
    end
  end

  def update_total_weight(date, user, new_total_weight)
    @pg.update_table_fields('biggestbass',"total_weight=\'#{new_total_weight}\', total_weight_date=\'#{date}\'", 'name', user)
  end

  def tally_weight(largemouth_weight = '0-0', smallmouth_weight = '0-0')
    largie = largemouth_weight.to_s.split('-')
    smallie = smallmouth_weight.to_s.split('-')
    combined_lbs = largie[0].to_i + smallie[0].to_i
    oz_total = largie[1].to_i + smallie[1].to_i
    lbs_from_oz = oz_total / 16
    remaining_oz = 0
    remaining_oz = (16 * lbs_from_oz) - oz_total if (16 * lbs_from_oz) > oz_total
    remaining_oz = oz_total - (16 * lbs_from_oz) if oz_total > (16 * lbs_from_oz)
    total = combined_lbs + lbs_from_oz
    "#{total}-#{remaining_oz}"
  end

  def convert_lbs_to_oz(weight_lbs_oz)
    weight = weight_lbs_oz.split('-')
    ((weight[0].to_i * 16) + weight[1].to_i)
  end

  def convert_oz_to_lbs(weight_oz)
    lbs = weight_oz.to_i / 16
    oz = 0
    oz = weight_oz.to_i - (lbs.to_i * 16) if weight_oz.to_i > (lbs.to_i * 16)
    oz = (lbs.to_i * 16) - weight_oz.to_i if (lbs.to_i * 16) > weight_oz.to_i
    "#{lbs}-#{oz}"
  end

  def update_deficit
    bb_hash = bb_table_hash.sort_by { |row| convert_lbs_to_oz(row['total_weight']).to_i }.reverse!
    leader_weight = convert_lbs_to_oz(bb_hash[0]['total_weight'])
    bb_hash.each do |row|
      total_weight_oz = convert_lbs_to_oz(row['total_weight'])
      diff_oz = leader_weight - total_weight_oz
      update_bb_field(row['name'], 'deficit', convert_oz_to_lbs(diff_oz))
    end
  end

  def update_rank
    # reset rank system
    bb_table_hash.each do |row|
      update_bb_field(row['name'], 'rank', nil)
    end
    bb_hash_with_entree_fee_paid = bb_table_hash.select { |row| row['entry_fee_paid'] }
    bb_hash = bb_hash_with_entree_fee_paid.sort_by { |row| convert_lbs_to_oz(row['entry_fee_paid_date']).to_i } if bb_table_hash.select { |row| row['total_weight'] != '0-0' }.count.zero?
    bb_hash = bb_hash_with_entree_fee_paid.sort_by { |row| convert_lbs_to_oz(row['total_weight']).to_i }.reverse! if !bb_table_hash.select { |row| row['total_weight'] != '0-0' }.count.zero?
    rank_hash = []
    bb_hash.each do |row|
      next if !rank_hash.select { |hash| hash['name'] == row['name'] }.count.zero?
      weight = row['total_weight']
      if weight != '0-0'
        matches = nil
        matches = bb_hash_with_entree_fee_paid.select { |hash| hash['total_weight'] == weight }
        if matches.nil? || matches.to_s.empty? || matches.count.zero?
          rank_hash << row if rank_hash.select { |hash| hash['name'] == row['name'] }.count.zero?
        end
        matches.sort_by { |hash| hash['total_weight_date'] }.each do |h|
          rank_hash << h if rank_hash.select { |hash| hash['name'] == h['name'] }.count.zero?
        end
      else
        matches = nil
        matches = bb_hash_with_entree_fee_paid.select { |hash| hash['total_weight'] == weight }
        if matches.nil? || matches.to_s.empty? || matches.count.zero?
          rank_hash << row if rank_hash.select { |hash| hash['name'] == row['name'] }.count.zero?
        end
        matches.sort_by { |hash| hash['entry_fee_paid_date'] }.each do |h|
          rank_hash << h if rank_hash.select { |hash| hash['name'] == h['name'] }.count.zero?
        end
      end
    end
    n = 0
    rank_hash.each do |row|
      rank = n += 1
      update_bb_field(row['name'], 'rank', rank)
      row.delete('entry_fee_paid_date')
      row.delete('largemouth_weight_date')
      row.delete('smallmouth_weight_date')
      row.delete('total_weight_date')
    end
    rank_hash
  end

  def bb_table_hash
    @pg.get_table_hash('biggestbass')
  end

  def sort_by_weight
    bb_table_hash.each do |row|
      update_bb_field(row['name'], 'largemouth_weight', '0-0') if row['largemouth_weight'].nil? || row['largemouth_weight'].to_s.empty?
      update_bb_field(row['name'], 'smallmouth_weight', '0-0') if row['smallmouth_weight'].nil? || row['smallmouth_weight'].to_s.empty?
      existing_total_weight = row['total_weight']
      new_total_weight = tally_weight(row['largemouth_weight'], row['smallmouth_weight'])
      @log.log_action(row['name'], "Upgraded total weight from #{existing_total_weight} to #{new_total_weight}") if new_total_weight != existing_total_weight
      update_total_weight(@log.get_datetime, row['name'], new_total_weight) if new_total_weight != existing_total_weight
    end
    update_deficit
    update_rank
  end

  def history_table
    @pg.db_generic_query_advance('bb_history', "ORDER BY datetime DESC LIMIT 50")
  end

  def convert_decimal_to_lbs_oz(decimal_weight)
    total_ounches = decimal_weight.to_f * 16
    pounds = total_ounches.to_i / 16
    ounces = total_ounches.to_i - (pounds * 16)
    "#{pounds}-#{ounces}"
  end

  def entry_fee_paid?(user, amount_due)
    user_info = @pg.db_query_user('biggestbass', user)
    return false if user_info.nil? || user_info.to_s.empty?
    return false if user_info['entry_fee_paid'].nil? || user_info['entry_fee_paid'].to_s.empty? || amount_due != user_info['entry_fee_paid']
    true
  end
end
