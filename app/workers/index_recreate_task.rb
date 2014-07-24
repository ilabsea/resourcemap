class IndexRecreateTask
  @queue = :index_recreate_queue

  def self.perform(collection_id)
    Collection.recreate_site_index(collection_id)
  end
end
