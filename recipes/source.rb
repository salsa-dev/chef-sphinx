#
# Cookbook Name:: sphinx
# Recipe:: default
#
# Copyright 2010, Alex Soto <apsoto@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
include_recipe "build-essential"
include_recipe "mysql::client"      if node[:sphinx][:use_mysql]
include_recipe "postgresql::client" if node[:sphinx][:use_postgres]
 
remote_file "#{Chef::Config[:file_cache_path]}/sphinx-#{node[:sphinx][:version]}.tar.gz" do
  source node[:sphinx][:url]
  not_if { ::File.exists?("#{Chef::Config[:file_cache_path]}/sphinx-#{node[:sphinx][:version]}.tar.gz") }
end

execute "Extract Sphinx source" do
  cwd Chef::Config[:file_cache_path]
  
  sphinx_path = "#{Chef::Config[:file_cache_path]}/sphinx-#{node[:sphinx][:version]}"
  
  code <<-EOH
    tar -zxvf #{sphinx_path}.tar.gz
    if test -e #{sphinx_path}-release; then mv #{sphinx_path}-release #{sphinx_path}; fi;
  EOH

  not_if { ::File.exists?(sphinx_path) }
end
 
if node[:sphinx][:use_stemmer] 
  remote_file "#{Chef::Config[:file_cache_path]}/libstemmer_c.tgz" do
    source node[:sphinx][:stemmer_url]
    not_if { ::File.exists?("#{Chef::Config[:file_cache_path]}/libstemmer_c.tgz") }
  end
 
  execute "Extract libstemmer source" do
    cwd Chef::Config[:file_cache_path]
    command "tar -C #{Chef::Config[:file_cache_path]}/sphinx-#{node[:sphinx][:version]} -zxf libstemmer_c.tgz"
    not_if { ::File.exists?("#{Chef::Config[:file_cache_path]}/sphinx-#{node[:sphinx][:version]}/libstemmer_c/src_c") }
  end
end
 
bash "Build and Install Sphinx Search" do
  cwd "#{Chef::Config[:file_cache_path]}/sphinx-#{node[:sphinx][:version]}"
  code <<-EOH
    ./configure #{node[:sphinx][:configure_flags].join(" ")}
    make
    make install
  EOH
  not_if { ::File.exists?("/usr/local/bin/searchd") }
end