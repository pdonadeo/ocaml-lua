
function fetch ()
  ci.log('I', 'Starting to fetch')
  if ci.exec('darcs', {'pull'}) ~= 0 then
    ci.log('E', 'darcs pull failed')
    return false
  end
  ci.log('I', 'darcs pull succeed')
  return true
end

function build () 
  ci.log('I', 'Starting to build')
  ci.putenv('VERSION', '0.1')
  if ci.exec("make", {}) ~= 0 then
    ci.log('E', 'make failed')
    return false
  end
  ci.log('I', 'make succeed')
  return true
end
