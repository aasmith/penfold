module ArgumentProcessor
  def process_args(hash)
    hash.each { |k,v| send(:"#{k}=", v) }
  end
end

