require File.join(File.dirname(__FILE__), 'helper')

class TestEvents < Test::Unit::TestCase
  test "events are registered" do
    bot = mock_bot {
      on(:channel, /Hello/) {msg "foo", "yr formal!"}
      on(:channel, /Hey/) {msg "foo", "bar baz"}
    }
    bot_is_connected

    bot.dispatch(:channel, :message => "Hey")
    assert_equal "PRIVMSG foo :bar baz\r\n", @server.gets
  end

  test "catch-all events" do
    bot = mock_bot {
      on(:channel) {msg "foo", "bar baz"}
    }
    bot_is_connected

    bot.dispatch(:channel, :message => "lolcat")
    assert_equal "PRIVMSG foo :bar baz\r\n", @server.gets
  end

  test "event can be halted" do
    bot = mock_bot {
      on(:channel, /Hey/) { halt; msg "foo", "bar baz" }
    }
    bot_is_connected

    bot.dispatch(:channel, :message => "Hey")
    assert @server.empty?
  end

  test "connect-event is dispatched at connection" do
    bot = mock_bot {
      on(:connect) {msg "foo", "bar baz"}
    }
    bot_is_connected

    assert_equal "PRIVMSG foo :bar baz\r\n", @server.gets
  end

  test "regular expression match is accessible" do
    bot = mock_bot {
      on(:channel, /foo (bar)/) {msg "foo", match[0]}
    }
    bot_is_connected

    bot.dispatch(:channel, :message => "foo bar")

    assert_equal "PRIVMSG foo :bar\r\n", @server.gets
  end

  test "regular expression matches are handed to block arguments" do
    bot = mock_bot {
      on :channel, /(foo) (bar)/ do |a,b|
        raw "#{a}"
        raw "#{b}"
      end
    }
    bot_is_connected

    bot.dispatch(:channel, :message => "foo bar")

    assert_equal "foo\r\n", @server.gets
    assert_equal "bar\r\n", @server.gets
  end

  test "propagate events with equals regular expressions" do
    bot = mock_bot {
      on :channel, /(foo)/ do |a|
        raw "#{a}1"
      end
      on :channel, /(foo)/ do |a|
        raw "#{a}2"
      end
    }
    bot_is_connected

    bot.dispatch(:channel, :message => "foo")

    assert_equal "foo1\r\n", @server.gets
    assert_equal "foo2\r\n", @server.gets
  end


  test "don't propagate events" do
    bot = mock_bot {
      on :channel, /(foo)/ do |a|
        raw "#{a}1"
        return false
      end
      on :channel, /(foo)/ do |a|
        raw "#{a}2"
      end
    }
    bot_is_connected

    bot.dispatch(:channel, :message => "foo")

    assert_equal "foo1\r\n", @server.gets
    assert_equal true, @server.empty?
  end
end
