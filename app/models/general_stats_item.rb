class GeneralStatsItem < ActiveRecord::Base
  attr_accessible :rank, :recent_avg_credit, :total_credit

  scope :ranked, where("total_credit IS NOT NULL").order("total_credit DESC")

  has_one :boinc_stats_item
  belongs_to :profile


end
