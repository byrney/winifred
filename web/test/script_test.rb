require 'test_helper'
require 'scripts'


class ScriptActionTest < MiniTest::Unit::TestCase
    def setup()
        @subject = ScriptAction.new({:interpreter => '/bin/bash', :script => "echo -n"}, nil)
    end

    def test_echo_results()
        expected = "output string"
        res = @subject.exec(expected)
        assert_equal("<pre>#{expected}</pre>", res[:body])
    end
end

class ScriptFileTest < MiniTest::Unit::TestCase
    def setup()
        this_dir = File.dirname(__FILE__)
        test_dir = File.join(this_dir, "test_folder")
        test_script = File.join(test_dir, "slow_script.sh")
        @subject = ScriptFileAction.new({:interpreter => '/bin/bash', :script => test_script}, nil)
    end

    def test_echo_goes_to_logfile()
        expected = "output string"
        res = @subject.exec(expected)
        assert_equal("menu", res[:type])
        logfile = res[:body].first[:query]
        pp "logfile = " + logfile
        tries = 5
        until tries <= 0 || File.size(logfile) > 0 do
            sleep(1)
            tries -= 1
        end
        File.open(logfile) { |f| assert_equal(expected, f.read())
        }
    end
end

class ScriptFilterTest < MiniTest::Unit::TestCase

    @@aws_script_output = <<-END
        <?xml version'1.0' ?>
        <items>
          <item uid="r53" arg="route53" autocomplete="r53" > <title>Amazon r53 Console</title> <subtitle>Route 53 DNS</subtitle> <icon >route53.png</icon> </item>
          <item uid="ec2" arg="ec2" autocomplete="ec2" > <title>Amazon EC2 Console</title> <subtitle>Elastic Compute</subtitle> <icon >ec2.png</icon> </item>
          <item uid="iam" arg="iam" autocomplete="iam" > <title>Amazon IAM Console</title> <subtitle>Identity Management</subtitle> <icon >iam.png</icon> </item>
          <item uid="vpc" arg="vpc" autocomplete="vpc" > <title>Amazon VPC Console</title> <subtitle>Virtual Provate Cloud</subtitle> <icon >vpc.png</icon> </item>
          <item uid="rds" arg="rds" autocomplete="rds" > <title>Amazon RDS Console</title> <subtitle>Relational Database</subtitle> <icon >rds.png</icon> </item>
        </items>
    END

    @@invalid_xml_outpit = <<-END
        error: this is not valid xml
    END

    def setup()
        @subject = ScriptFilter.new({:interpreter => '/bin/bash', :script => "echo -n"}, nil)
    end

    def test_process_xml_results()
        output = @@aws_script_output
        success = true
        query = "whatever"
        res = @subject.process_script_output(query, output, success)
        assert_equal("menu", res[:type])
        assert_equal(5, res[:body].size)
        first = res[:body].first
        assert_equal("Amazon r53 Console", first[:title])
        assert_equal("Route 53 DNS", first[:subtitle])
        assert_equal("route53.png", first[:icon])
        assert_equal("route53", first[:query])
    end

    def test_invalid_xml()
        output = @@invalid_xml_outpit
        success = true
        query = "whatever"
        assert_raises(RuntimeError) do
            @subject.process_script_output(query, output, success)
        end
    end

end

