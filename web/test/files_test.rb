
require 'test_helper'
require 'files'


class FileBrowserTest < MiniTest::Unit::TestCase

    def setup()
        this_dir = File.dirname(__FILE__)
        @test_dir = File.join(this_dir, "test_folder")
    end

    def check_items(items)
        items.each do |entry|
            assert(File.exists?(entry[:query]))
            expected_action = nil
            if(File.directory?(entry[:query]))
                expected_action = "self"
            end
            assert_equal(expected_action, entry[:action])

        end
    end
    def test_root_folder_with_no_query()
        dbg = FileBrowser.new(@test_dir, nil)
        refute_nil(dbg)
        result = dbg.exec({})
        assert_equal("menu", result[:type])
        items = result[:body]
        check_items(items)
    end

    def test_can_create()
        dbg = FileBrowser.new(@test_dir, nil)
        refute_nil(dbg)
    end

    def test_unknown_paths_raise()
        dbg = FileBrowser.new("/xyznonexistentdirectory", nil)
        assert_raises(RuntimeError) do
            dbg.exec({})
        end
    end

    def test_with_valid_dir_items_are_sane()
        puts "TestDir=" + @test_dir
        dbg = FileBrowser.new(@test_dir, nil)
        result = dbg.exec(File.join(@test_dir, "subfolder"))
        refute_nil(result)
        assert_equal("menu", result[:type])
        check_items(result[:body])
    end

    def test_current_dir_not_as_dot_in_listing()
        dbg = FileBrowser.new(@test_dir, nil)
        result = dbg.exec(File.join(@test_dir, "subfolder"), nil)
        refute_nil(result)
        assert_equal("menu", result[:type])
        items = result[:body]
        items.each { |v| refute_equal(".", v[:title]) }
    end

    def test_batching()
        subject = FileBrowser.new(@test_dir, nil)
        batch = 4
        subject.batch_size = batch
        item_count = 0
        position = nil
        folder = File.join(@test_dir, "subfolder10")
        loop do
            result = subject.exec(folder, position)
            refute_nil(result)
            assert_equal("menu", result[:type])
            items = result[:body]
            item_count += items.size
            position = result[:position]
            break if(position == nil)
        end
        expected_count = 10 + 1   #  10 files plus parent folder
        assert_equal(expected_count, item_count)
    end
end


class FileActionsTest < MiniTest::Unit::TestCase

    def setup()
        this_dir = File.dirname(__FILE__)
        @test_dir = File.join(this_dir, "test_folder")
        @valid_file = File.join(@test_dir, "normal_file.txt")
    end

    def test_can_create()
        p = FileActions.new(nil, nil)
        refute_nil(p)
    end

    def test_can_exec()
        p = FileActions.new(nil, nil)
        refute_nil(p)
        res = p.exec(@valid_file)
        assert_equal("menu", res[:type])
    end

end


class TailTest < MiniTest::Unit::TestCase
    def setup()
        @subject = Tail.new(nil, nil)
        this_dir = File.dirname(__FILE__)
        @test_dir = File.join(this_dir, "test_folder")
        @short_file = File.join(@test_dir, "normal_file.txt")
    end

    def test_nil_query()
        assert_raises(RuntimeError) { @subject.exec(nil, nil) }
    end

    def test_invalid_filename()
        assert_raises(RuntimeError) { @subject.exec('/file/that/does/not/exist.txt', nil) }
    end
    def test_short_file()
        resp = @subject.exec(@short_file, nil)
        refute_nil(resp)
        assert_equal(File.size(@short_file), resp[:position], "tail should haave read to the end and returned the file size")
        pp resp
    end

end
