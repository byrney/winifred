require 'test_helper'
require 'process'

class ProcessTestSetup < MiniTest::Unit::TestCase

    def setup()
        @this_pid = Process.pid
        @running_process = Kernel.spawn('sleep', '3001')
    end

    def teardown()
        pid = Process.waitpid(@running_process, Process::WNOHANG)  # check it's finished
        unless(pid)
            Process.kill("KILL", @running_process)
        end
    rescue
        Process.detach(@running_process)
    end
end

class ProcessListTests < ProcessTestSetup

    def setup()
        @subject = ProcessList.new("pid,ppid", nil)
        super
    end

    def test_can_exec_no_filter()
        res = @subject.exec(nil, nil)
        assert_equal("menu", res[:type])
        refute_nil(res[:body])
    end

    def get_pids(res)
        res[:body].collect {|v| v[:query].to_i }
    end

    def test_ruby_filter_finds_this_process()
        res = @subject.exec('ruby', nil)
        assert_equal("menu", res[:type])
        refute_nil(res[:body])
        pids = get_pids(res)
        assert_includes(pids, @this_pid)
        refute_includes(pids, @running_process)
    end

    def test_nonmatching_filter_skips_this_process()
        res = @subject.exec('xyzabc123%%%%%%%', nil)
        assert_equal("menu", res[:type])
        refute_nil(res[:body])
        pids = get_pids(res)
        refute_includes(pids, @this_pid)
    end


end

class ProcessActionsTests < ProcessTestSetup

    def setup()
        @signals = %w(KILL TERM HUP)
        @subject = ProcessActions.new(@signals.join("|"), nil)
        super
    end

    def test_construct_default_spec()

        temp_subject = ProcessActions.new(nil, nil)
        res = temp_subject.exec(@running_process.to_s, nil)
        assert_equal(["KILL"], res[:body].collect{|x| x[:title]})
    end

    def test_menu_when_no_signal()
        res = @subject.exec(@running_process.to_s, nil)
        assert_equal("menu", res[:type])
        assert_equal(@signals, res[:body].collect{|x| x[:title]})
    end

    def test_kill_process()
        query = @running_process.to_s + ":TERM"
        res = @subject.exec(query, nil)
        assert_equal("html", res[:type])
        assert_equal(@running_process, Process.waitpid(@running_process, Process::WNOHANG))  # check it's finished
    end

end
