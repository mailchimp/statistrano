module Given
  ROOT = Dir.pwd
  TMP  = File.join( Dir.pwd, 'tmp' )

  class << self

    def fixture name
      cleanup!

      `rsync -av ./spec/fixtures/#{name}/ #{TMP}/`
      Dir.chdir TMP
    end

    def no_file name
      FileUtils.rm name, force: true
    end

    def symlink source, destination
      no_file destination
      FileUtils.symlink File.expand_path(source),
                        File.expand_path(destination),
                        force: true
    end

    def file name, content
      file_path = File.join( TMP, name )
      FileUtils.mkdir_p( File.dirname(file_path) )
      File.open( file_path, 'w' ) do |file|
        file.write content
      end
    end

    def cleanup!
      Dir.chdir ROOT
      `rm -rf #{TMP}`
    end

  end
end
