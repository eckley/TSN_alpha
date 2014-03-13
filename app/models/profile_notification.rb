class ProfileNotification < ActiveRecord::Base
  table_name = :profile_notifications
  attr_accessible :body, :read, :subject,:aggregatable, :aggregator_count, :aggregation_text, :profile, :notifier
  belongs_to :profile
  belongs_to :notifier, polymorphic: true
  scope :unread, where{read == false}.order{created_at.asc}
  def is_read?
    read?
  end
  def mark_as_read
    self.read = true
    self.save
  end
  class << self
    def notify(profile,subject,body,notifier=nil,aggregatable=false, aggregation_text = '')
      note = new({
          profile: profile,
          subject: subject,
          body: body,
          notifier: notifier,
          aggregatable: aggregatable,
          aggregation_text: aggregation_text,
          aggregator_count: 1,
          read: false,
            })
      note.save
    end

    #aggrigate type can be either 'class' or 'class_id'. the first aggrigates all matching notigier types the second inlcudes notifier id
    #if the notification is to be aggrigated aggregation subject and body are user
    #  all occurances of %COUNT% in subject and body are replaced with the aggregator_count
    def notify_with_aggrigation(profile,subject,body,aggregation_subject,aggregation_body,aggrigate_type,notifier, aggregation_text)
      #checks and deletes other similar notifications
      agg_count = aggregation_relation(profile,notifier,aggrigate_type).sum(:aggregator_count)

      if agg_count == 0
        #first notification so just notify normally
        notify(profile,subject,body,notifier,true,aggregation_text)
      else
        ProfileNotification.transaction do
          #aggregation texts is an array of all the pre existing aggregation text's stored in DB
          aggregation_texts = aggregation_relation(profile,notifier,aggrigate_type).pluck(:aggregation_text)
          aggregation_relation(profile,notifier,aggrigate_type).delete_all
          new_subject = aggregation_subject.sub('%COUNT%',(agg_count+1).to_s)
          aggregation_texts << aggregation_text
          aggregation_text_new = aggregation_texts.join('')
          new_body = aggregation_body.sub('%COUNT%',(agg_count+1).to_s) + '<br />' + aggregation_text_new
          note = new({
                           profile: profile,
                           subject: new_subject,
                           body: new_body,
                           notifier: notifier,
                           aggregatable: true,
                           aggregator_count: agg_count+1,
                           aggregation_text: aggregation_text_new,
                           read: false,
                       })
          note.save
        end
      end
    end

    def notify_all(profiles,subject,body,notifier=nil,aggregatable=false)
      #notfies all profiles
      #improves efficacy by using direct SQL inserts


    end


    #returns a relation object for all the too be aggregated notifications
    def aggregation_relation(profile,notifier,aggrigate_type)
      relation_out = where{profile_id == my{profile.id}}.
                        where{aggregatable == true}.
                        where{read == false}.
                        where{notifier_type == my{notifier.nil? ? nil : notifier.class.to_s}}
      relation_out = relation_out.where{notifier_id == my{notifier.nil? ? nil : notifier.id}} if aggrigate_type == 'class_id'
      relation_out
    end

  end
end
