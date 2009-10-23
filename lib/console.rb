def reload!
  load 'fog_machine.rb'
  Recipe.reload!
end
