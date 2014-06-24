#!/usr/bin/env ruby
# encoding: utf-8
require 'yaml'
require 'find'
require 'fileutils'

# read the config files
ig = "/Users/peacock/php/demo/.scpignore"
rules = "/Users/peacock/php/demo/.replacerules"
sourcedir = "~/php/demo"
target_name = "demo"
# create a temp folder in /var/tmp
dest = "/var/tmp/" + target_name


Dir.mkdir(dest)
# ignore files
ignore_yaml = ""
File.new("#{ig}", 'r').each do |line|
  ignore_yaml << line
end

ignores = YAML::load(ignore_yaml)
ignores.each do |ignore|
  #puts ignore
end

# copy the files
Dir.foreach(File.expand_path(sourcedir)) do |path|
  match_flag = false
  ignores.each do |ignore|
    if path == ignore
      match_flag = true
      break
    end
  end
  if match_flag
    puts "matched file" + path
    next
  end
  path = File.expand_path(sourcedir) + "/" + path
  if FileTest.directory?(path)
    if File.basename(path)[0] != ?. # . ..
      puts "copy dir " + path
      FileUtils.cp_r(path, dest)
    end
  else
    puts "copy file " + path
    FileUtils.cp(path,dest)
  end
end

# replace rules
rules_yaml = ""
File.new("#{rules}", 'r').each do |line|
  rules_yaml << line
end

rules = YAML::load(rules_yaml)

Find.find(File.expand_path(dest)) do |path|
  #puts File.basename(path)
  #puts path

  if FileTest.directory?(path)
    if File.basename(path)[0] == ?.
      Find.prune # Don't look any further into this directory
    else
      next
    end
  else
    # is a file
    rules.each do |rule|
      rule.each do |file, value|
        full_replace_path = dest + "/" + file
        if path.index(full_replace_path)
          puts "matched"
          puts "repl:" + full_replace_path
          value.each do |replace_rule|
            puts "if find " + Regexp.escape(replace_rule.keys[0]) + ", replace to:" + replace_rule.values[0]
            pattern_str = Regexp.escape(replace_rule.keys[0])
            replace_str = replace_rule.values[0]

            # open this file
            lines = ""
            cur_file = File.open(path, "r")
            begin
              cur_file.each do |line|
              #File.open(path, "r+").each do |line|
                if line =~ /#{pattern_str}/
                  puts "a line should replace:" + line
                end
                line.gsub!(/#{pattern_str}/, replace_str)
                lines << line
              end
            rescue ArgumentError
              # invalid byte sequence in UTF-8 (ArgumentError)
              puts "ArgumentError"
            end
            cur_file.close
            cur_file = File.open(path, "w")
            #puts lines
            #File.open(path, "w").printf("%s", lines)
            cur_file.printf("%s", lines)
            cur_file.close
          end
        end
      end
    end
  end
end

=begin
# copy to the sever
Dir.foreach(File.expand_path(dest)) do |path|
  path = "#{File.expand_path(dest)}/#{path}"
  #puts File.basename(path)
  if FileTest.directory?(path)
    puts "DIR #{path}"
    if File.basename(path)[0] == ?. # contain . .. .git
      puts "#{path}\t pruned"
      #Find.prune # Don't look any further into this directory
    else
      #next
      if File.fnmatch("git", File.basename(path))
        puts "is git folder"
      else
        `scp -i ~/.ssh/example.pem -r #{path} ubuntu@www.example.com:~/#{target_name}/`
      end
    end
  else
  puts "FILE #{path}"
    # is a file
  `scp -i ~/.ssh/example.pem #{path} ubuntu@www.example.com:~/#{target_name}/`
  end
end
=end
