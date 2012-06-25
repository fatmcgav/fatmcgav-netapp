#============================================================#
#                                                            #
# $ID:$                                                      #
#                                                            #
# NaServer.rb                                                #
#                                                            #
# Client-side interface to ONTAP and DataFabric Manager APIs.#
#                                                            #
# Copyright (c) 2011 NetApp, Inc. All rights reserved.       #
# Specifications subject to change without notice.           #
#                                                            #
#============================================================#

require 'net/http'
require 'net/https'
require 'rexml/document'
require 'rexml/streamlistener'
include REXML
require 'stringio'
include StreamListener
require 'NaElement'


# Class for managing Network Appliance(r) Storage System
# using ONTAPI(tm) and DataFabric Manager API(tm).
#
# An NaServer encapsulates an administrative connection to
# a NetApp Storage Systems running Data ONTAP 6.4 or later.
# NaServer can also be used to establish connection with
# DataFabric Manager (DFM). You construct NaElement objects
# that represent queries or commands, and use invoke_elem()
# to send them to the storage systems or DFM server. Also,
# a convenience routine called invoke() can be used to bypass
# the element construction step.  The return from the call is
# another NaElement which either has children containing the
# command results, or an error indication.
#
# The following routines are available for setting up
# administrative connections to a storage system or DFM server.
#

$ZAPI_stack = []
$ZAPI_atts = {}
$tag_element_stack = []

class NaServer

  #dtd files
  FILER_dtd = 'file:/etc/netapp_filer.dtd'
  DFM_dtd = 'file:/etc/netapp_dfm.dtd'
  AGENT_dtd = 'file:/etc/netapp_agent.dtd'

  #URLs
  AGENT_URL = '/apis/XMLrequest'
  FILER_URL = '/servlets/netapp.servlets.admin.XMLrequest_filer'
  NETCACHE_URL = '/servlets/netapp.servlets.admin.XMLrequest'
  DFM_URL = '/apis/XMLrequest'

  ZAPI_xmlns = 'http://www.netapp.com/filer/admin'

  # Create a new connection to server 'server'.  Before use,
  # you either need to set the style to "hosts.equiv" or set
  # the username (always "root" at present) and password with
  # set_admin_user().

  def initialize(server, major_version, minor_version)
    @server = server
    @major_version = major_version
    @minor_version = minor_version
    @transport_type = "HTTP"
    @port = 80
    @user = "root"
    @password = ""
    @style = "LOGIN"
    @timeout = 0
    @vfiler = ""
    @servertype = "FILER"
    @debug_style = ""
    @xml = ""
    @enable_server_cert_verification = false
    @enable_hostname_verification = false
    @cert_file = nil
    @key_file = nil
    @key_passwd = nil
    @ca_file = nil
    @url = FILER_URL
    @dtd = FILER_dtd
  end


  # Pass in 'LOGIN' to cause the server to use HTTP simple
  # authentication with a username and password.  Pass in 'HOSTS'
  # to use the hosts.equiv file on the filer to determine access
  # rights (the username must be root in that case). Pass in
  # 'CERTIFICATE' to use certificate based authentication with the
  # DataFabric Manager server.
  # 
  # If $style = CERTIFICATE, you can use certificates to authenticate
  # clients who attempt to connect to a server without the need of
  # username and password. This style will internally set the transport
  # type to HTTPS. Verification of the server's certificate is required
  # in order to properly authenticate the identity of the server.
  # Server certificate verification will be enabled by default using this
  # style and Server certificate verification will always enable hostname
  # verification. You can disable server certificate (with hostname) 
  # verification using set_server_cert_verification().
  
  def set_style(style)
    if(!style.eql?("HOSTS") and !style.eql?("LOGIN") and !style.eql?("CERTIFICATE"))
        return fail_response(13001, "NaServer::set_style: bad style \"" + style + "\"")
    end
    if (style.eql?("CERTIFICATE"))
        ret = set_transport_type("HTTPS")
        if (ret)
            return ret
        end
        @enable_server_cert_verification = true
        @enable_hostname_verification = true
    else
        @enable_server_cert_verification = false
        @enable_hostname_verification = false
    end
    @style = style
    return nil
  end


  # Get the authentication style

  def get_style()
    return @style
  end


  # Set the admin username and password.  At present 'user' must always be 'root'.

  def set_admin_user(user, password)
    @user = user
    @password = password
  end



  # Pass in one of these keywords: 'FILER' or 'DFM' to indicate
  # whether the server is a storage system (filer) or a DFM server.
  #
  # If you also use set_port(), call set_port() AFTER calling this routine.
  #
  # The default is 'FILER'.

  def set_server_type(server_type)
    if (server_type.casecmp('filer') == 0)
        @url = FILER_URL
        @dtd = FILER_dtd
    elsif (server_type.casecmp('netcache') ==  0)
        @url = NETCACHE_URL
        @port = 80
    elsif (server_type.casecmp('agent') ==  0)
        @url = AGENT_URL
        @port = 4092
        @dtd = AGENT_dtd  
    elsif (server_type.casecmp('dfm') ==  0)
        @url = DFM_URL
        @port = 8088
        @dtd = DFM_dtd
        if(@transport_type == "HTTPS")
            @port = 8488
        end
    else
        return fail_response(13001, "NaServer::set_server_type: bad type \"" + server_type + "\"")
    end
    @servertype = server_type
    return nil
  end


  # Get the type of server this server connection applies to.

  def get_server_type()
    return @servertype
  end


  # Override the default transport type.  The valid transport
  # type are currently 'HTTP' and 'HTTPS'.

  def set_transport_type(scheme)
    if(!scheme.eql?("HTTP") and !scheme.eql?("HTTPS"))
        return fail_response(13001, "NaServer::set_transport_type: bad type \" " + scheme + "\"")
    end
    if(scheme.eql?("HTTP"))
        @transport_type = "HTTP"
        if(@server_type.eql?("DFM"))
            @port = 8088
        else
            @port = 80
        end
    elsif(scheme.eql?("HTTPS"))
        @transport_type = "HTTPS"
        if(@server_type.eql?("DFM"))
            @port = 8488
        else
            @port = 443
        end
    end
    return nil
  end


  # Retrieve the transport used for this connection.
  
  def get_transport_type()
    return @transport_type
  end


  # Set the style of debug.
  
  def set_debug_style(debug_style)
    if(!debug_style.eql?("NA_PRINT_DONT_PARSE"))
      return fail_response(13001, "NaServer::set_debug_style: bad style \"" + debug_style + "\"")
    else
      @debug_style = debug_style
    end
  end


  # Override the default port for this server.  If you
  # also call set_server_type(), you must call it before
  # calling set_port().
  
  def set_port(port)
    @port = port
  end


  # Retrieve the port used for the remote server.
  
  def get_port()
    return @port
  end


  # Check the type of debug style and return the
  # value for different needs. Return true if debug style
  # is NA_PRINT_DONT_PARSE,	else return false.
  
  def is_debugging()
    if(@debug_style.eql?("NA_PRINT_DONT_PARSE"))
        return true
    else
    return false
    end
  end


  # Return the raw XML output.
  
  def get_raw_xml_output()
    return @xml
  end


  # Save the raw XML output.

  def set_raw_xml_output(xml)
    @xml = xml
  end


  # Determines whether https is enabled.

  def use_https()
    if(@transport_type.eql?("HTTPS"))
      return true
    else
      return false
    end
  end


  def parse_raw_xml(xmlresponse)
    xml_response = StringIO.new(xmlresponse)
    Document.parse_stream(xml_response, MyListener.new)
    if($tag_element_stack.length > 0)
        print("\nError : No corresponding end tag for the element \"" + $tag_element_stack.pop() + "\"\n")
        exit
    end
    stack_len = $ZAPI_stack.length
    if(stack_len <= 0)
        return fail_response(13001, "Zapi::parse_xml-no elements on stack")
    end
    r = $ZAPI_stack.pop()
    return r
  end



  def parse_xml(xmlresponse)
    xml_response = StringIO.new(xmlresponse)
    Document.parse_stream(xml_response, MyListener.new)
    if($tag_element_stack.length > 0)
        print("\nError : No corresponding end tag for the element \"" + $tag_element_stack.pop() + "\"\n")
        exit
    end
    stack_len = $ZAPI_stack.length 	
    if(stack_len <= 0)
        return fail_response(13001, "Zapi::parse_xml-no elements on stack")
    end
    r = $ZAPI_stack.pop()
    if (r.name != "netapp")
        return fail_response(13001, "Zapi::parse_xml - Expected <netapp> element but got" + r.name)
    end	
    results = r.child_get("results")
    unless(results)
        return fail_response(13001, "Zapi::parse_xml - No results element in output!")
    end
    return results
  end


  # Submit an XML request already encapsulated as
  # an NaElement and return the result in another
  # NaElement.

  def invoke_elem(req)  
    xmlrequest = req.toEncodedString()	
    vfiler_req = ""
    if(!@vfiler.eql?(""))
        vfiler_req = " vfiler=\"" + @vfiler + "\""
    end
    content = "<?xml version=\'1.0\' encoding=\'utf-8\'?>" +
              "\n" +
          "<!DOCTYPE netapp SYSTEM \'" + @dtd + "\'>" +
          "\n" +
          "<netapp" +
          vfiler_req +
          " version='" + @major_version.to_s() + "." + @minor_version.to_s() + "' xmlns='" + ZAPI_xmlns + "'>" +
          xmlrequest +
          "</netapp>"
    if(@debug_style.eql?("NA_PRINT_DONT_PARSE"))
        print("INPUT \n " + content)
    end

    begin
        http = Net::HTTP.new(@server, @port)
        if(@transport_type.eql?("HTTPS"))
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            # Server Certificate Verification
            if(@enable_server_cert_verification.eql?(true))
                http.ca_file = @ca_file
                http.verify_mode = OpenSSL::SSL::VERIFY_PEER | OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
                unless(@enable_hostname_verification)
                    OpenSSL::SSL.module_eval do
                        verify_method = method(:verify_certificate_identity)
                        metaclass = class << OpenSSL::SSL; self; end
                        metaclass.send :define_method, :verify_certificate_identity do |cert, hostname|
                            true
                        end
                    end
                end
            end
            # Client Certificate Verification
            if(@cert_file != nil)
                pem = File.read(@cert_file)
                http.cert = OpenSSL::X509::Certificate.new(pem)
                # @key_file is nil when the certificate and key are in the same file (@cert_file)
                if(@key_file == nil)
                    http.key = OpenSSL::PKey::RSA.new(pem)
                else
                    key = File.read(@key_file)
                    http.key = OpenSSL::PKey::RSA.new(key, @key_passwd)
                end
            end
        end
        if(@timeout > 0)
            http.open_timeout = @timeout
            http.read_timeout = @timeout
        end
        request = Net::HTTP::Post.new(@url)
        if(!@style.eql?("HOSTS"))
            request.basic_auth @user, @password
        end
        request.content_type = "text/xml; charset=\"UTF-8\""
        request.body = content
        response = http.start {|http| http.request(request)}
    rescue Timeout::Error => msg
        print("\nError : ")
        return fail_response(13001, msg)
    rescue Errno::ECONNREFUSED => msg
        print("\nError : ")
        return fail_response(111, msg)
    rescue OpenSSL::SSL::SSLError => msg
        return fail_response(13001, msg)
    rescue => msg 
        print("\nError : ")
        return fail_response(13001, msg)
    end

    if(!response)
        return fail_response(13001,"No response received")
    end
    if(response.code.eql?("401"))
        return fail_response(13002,"Authorization failed")
    end
    return parse_xml(response.body)
  end


   #A convenience routine which wraps invoke_elem().
   #It constructs an NaElement with name $api, and for
   #each argument name/value pair, adds a child element
   #to it.  It's an error to have an even number of
   #arguments to this function.
   #Example: myserver->invoke('snapshot-create',
   #                                'snapshot', 'mysnapshot',
   #                            'volume', 'vol0');
   #

  def invoke(api, *args)
    num_parms = args.length	
    if ((num_parms & 1) != 0)
        return self.fail_response(13001, "in Zapi::invoke, invalid number of parameters")
    end	
    xi = NaElement.new(api)
    i = 0
    while(i < num_parms)
        key = args[i]
    i = i + 1
    value = args[i]
    i = i + 1
    xi.child_add(NaElement.new(key, value))
    end
    return invoke_elem(xi)
  end


  #Sets the vfiler name. This function is used for vfiler-tunneling.

  def set_vfiler(vfiler_name)
    if(@major_version >= 1 and @minor_version >= 7)
        @vfiler = vfiler_name
        return 1
    end
    return 0
  end


  # Sets the vserver name. This function is used for vfiler-tunneling.
  # However, vserver tunneling actually uses vfiler-tunneling.
  # Hence this function internally sets the vfiler name.

  def set_vserver(vserver_name)
    if(@major_version >= 1 and @minor_version >= 15)
        @vfiler = vserver_name
        return 1
    end
    print("\nONTAPI version must be at least 1.15 to send API to a vserver\n")
    return 0
  end


  # Gets the vserver name. This function is added for vserver-tunneling.
  # However, vserver tunneling actually uses vfiler-tunneling. Hence this
  # function actually returns the vfiler name.

  def get_vserver()
    return @vfiler
  end


  #Sets the connection timeout value, in seconds,for the given server context.

  def set_timeout(timeout)
    @timeout = timeout
  end


  #Retrieves the connection timeout value (in seconds) for the given server context.
  
  def get_timeout()    
    return @timeout
  end


  # Enables or disables server certificate verification by the client.
  # Server certificate verification is enabled by default when style
  # is set to CERTIFICATE. Hostname (CN) verification is always enabled
  # during server certificate verification.

  def set_server_cert_verification(enable)
    unless(enable.eql?(true) or enable.eql?(false))
        return fail_response(13001, "NaServer::set_server_cert_verification: invalid argument " + enable + "specified");
    end
    unless (use_https())
        return fail_response(13001, "NaServer::set_server_cert_verification: server certificate verification can only be enabled or disabled for HTTPS transport")
    end
    @enable_server_cert_verification = enable
    @enable_hostname_verification = enable
    return nil
  end


  # Determines whether server certificate verification is enabled or not.
  # Returns true if it is enabled, else returns false.


  def is_server_cert_verification_enabled()
    return @enable_server_cert_verification
  end


  # Sets the client certificate and key files that are required for client authentication
  # by the server using certificates. If key file is not defined, then the certificate file 
  # will be used as the key file.


  def set_client_cert_and_key (cert_file, key_file = nil, key_passwd = nil)
    unless(cert_file)
        return fail_response(13001, "NaServer::set_client_cert_and_key: certificate file not specified")
    end
    @cert_file = cert_file
    @key_file = key_file
    if(key_passwd == nil)
        @key_passwd = ""
    else
        @key_passwd = key_passwd
    end

    return nil
  end


  # Specifies the certificates of the Certificate Authorities (CAs) that are 
  # trusted by this application and that will be used to verify the server certificate.


  def set_ca_certs (ca_file)
    if(ca_file == nil)
        return fail_response(13001, "NaServer::set_ca_certs: missing CA certificate file")
    end
    @ca_file = ca_file

    return nil
  end


  # Enables or disables hostname verification by the client during server certificate the 
  # server certificate.


  def set_hostname_verification (enable)
    unless(enable.eql?(true) or enable.eql?(false))
        return fail_response(13001, "NaServer::set_hostname_verification: invalid argument " + enable + "specified");
    end
    unless (@enable_server_cert_verification)
        return fail_response(13001, "NaServer::set_hostname_verification: server certificate verification is not enabled")
    end
	@enable_hostname_verification = enable
    return nil
  end


  # Determines whether hostname verification is enabled or not.
  # Returns true if it is enabled, else returns false


  def is_hostname_verification_enabled ()
	return @enable_hostname_verification
  end






  # "private" subroutines for use by the public routines
  # This is a private function, not to be called from outside NaServer
  # This is used when the transmission path fails, and we don't actually
  # get back any XML from the server.

  def fail_response(errno, reason)
    n = NaElement.new("results")
    n.attr_set("status", "failed")
    n.attr_set("reason", reason)
    n.attr_set("errno", errno)
    return n
  end
end


class MyListener

  def tag_start(element, attributes)
    n = NaElement.new(element)
    $tag_element_stack.push(element)
    $ZAPI_stack.push(n)
    attributes.each { |key, value| $ZAPI_atts[key] = value ; n.attr_set(key, value) }
  end

  def tag_end(element)
    stack_len = $ZAPI_stack.length
    if($tag_element_stack.length <= 0)
        print("\nError : Missing start tag for " + element + "\n")
        exit
    end
    tag_element = $tag_element_stack.pop()
    if(not tag_element.eql?(element))
        print("\nError : Missing start tag for " + element + "\n")
        exit
    end
    if(stack_len > 1) 
        n = $ZAPI_stack.pop()
        i = $ZAPI_stack.length
    if(i != stack_len - 1)
        print("pop did not work!!!!\n")
    end
    $ZAPI_stack[i-1].child_add(n)
    end	
  end

  def text(text)
    text = text.chomp
    i = $ZAPI_stack.length
    if(text.length > 0 and i > 0)
        $ZAPI_stack[i-1].add_content(text)
    end
  end
end

