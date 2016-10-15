module Rake
  module DSL
    def before(task_name, new_tasks = nil, &new_task)
      task_name = task_name.to_s
      new_tasks = [new_tasks].flatten.compact
      old_task = Rake.application.instance_variable_get('@tasks').delete(task_name)

      Hem::Metadata.to_store task_name
      task task_name => new_tasks | old_task.prerequisites do
        new_task.call unless new_task.nil?
        old_task.invoke
      end
    end
  end
end
