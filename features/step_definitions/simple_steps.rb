class Simple
  def testit
    "pass"
  end
end

Given(/^a simple$/) do
  @simple = Simple.new
end

When(/^tested$/) do
  @message = @simple.testit
end

Then(/^it should (.*)$/) do |mess|
  expect(@message).to eq(mess)
end
