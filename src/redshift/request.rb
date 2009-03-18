class Red::MethodCompiler
  # complete
  def rb_process_scripts
    add_function :rb_doc_exec_js, :rb_strip_scripts
    <<-END
      function rb_process_scripts(xhr, eval_response, eval_scripts) {
        var retval;
        var string = xhr.responseText || '';
        if (eval_response || /(ecma|java)script/.test(xhr.getResponseHeader('Content-Type'))) {
          return rb_doc_exec_js(string);
        } else {
          return rb_strip_scripts(string, eval_scripts);
        }
      }
    END
  end
  
  # 
  def rb_query_data_to_string
    <<-END
      function rb_query_data_to_string(tbl, base) {
        var ary = [];
        var base_p = (base != '');
        for (var x in tbl) {
          if (NIL_P(tbl[x])) { continue; }
          var key = rb_id2name(rb_to_id(x));
          var value = tbl[x];
          var kv_pair = '';
          if (base_p) { key = base + '[' + key + ']'; }
          switch (TYPE(value)) {
            case T_HASH:
              kv_pair = rb_query_data_to_string(value.tbl, key);
              break;
            case T_STRING:
              kv_pair = key + '=' + encodeURIComponent(value.ptr);
              break;
            default:
              // add in an error here
          }
          ary.push(kv_pair);
        }
        console.log(ary.join('&'));
        return ary.join('&');
      }
    END
  end
  
  # 
  def rb_req_parameters
    add_function :rb_intern, :rb_check_type, :rb_query_data_to_string, :rb_id2name, :rb_to_id
    <<-END
      function rb_req_parameters(req, tbl) {
        var param;
        var sym = function(string) { return tbl[ID2SYM(rb_intern(string))] || 0; };
        
        if ((param = sym('url'))) {
          Check_Type(param, T_STRING);
          req.url = param.ptr;
        }
        
        if ((param = sym('data'))) {
          Check_Type(param, T_HASH);
          req.data = rb_query_data_to_string(param.tbl, '');
        }
        
        if ((param = sym('format'))) {
          Check_Type(param, T_STRING);
          req.format = 'format=' + param.ptr;
        }
        
        if ((param = sym('method'))) {
          req.method = rb_id2name(rb_to_id(param)).toUpperCase();
        }
        
        if ((param = sym('emulation')) && RTEST(param) && /^(?:DELETE|PUT)$/i.test(req.method)) {
          var _method = '_method=' + req.method.toUpperCase();
          req.data = (req.data == '') ? _method : (_method + '&' + req.data);
          req.method = 'POST';
        }
        
        if ((param = sym('encoding'))) {
          Check_Type(param, T_STRING);
          req.encoding = param.ptr;
        }
        
        if ((param = sym('headers'))) {
          Check_Type(param, T_HASH);
          var h_tbl = param.tbl;
          var headers = req.headers;
          for (var x in h_tbl) {
            var val = h_tbl[x] || Qnil;
            Check_Type(val, T_STRING);
            headers[rb_id2name(rb_to_id(x))] = val.ptr;
          }
        }
        
        if ((param = sym('url_encoded')) && RTEST(param) && (req.method == 'POST')) {
          var encoding = (req.encoding) ? ('; charset=' + req.encoding) : '';
          req.headers['Content-type'] = 'application/x-www-form-urlencoded' + encoding;
        }
        
        if (req.data && (req.method == 'GET')) {
          var separator = (/[?]/.test(req.url)) ? '&' : '?';
          req.url = [req.url, req.data].join(separator);
          req.data = 0;
        }
        
        if ((param = sym('eval_response'))) {
          req.eval_response = RTEST(param);
        }
        
        if ((param = sym('eval_scripts'))) {
          req.eval_scripts = RTEST(param);
        }
      }
    END
  end
  
  # complete
  def rb_strip_scripts
    add_function :rb_doc_exec_js
    <<-END
      function rb_strip_scripts(string, eval_scripts) {
        var scripts = '';
        var fn = function(x,y) {
          scripts += (y + '\\n');
          return '';
        };
        var retval = string.replace(/<script[^>]*>([\\s\\S]*?)<\\/script>/gi,fn);
        if (eval_scripts) { rb_doc_exec_js(scripts); }
        return retval;
      }
    END
  end
  
  # complete
  def req_cancel
    <<-END
      function req_cancel(req) {
        if (req.running) {
          req.running = Qfalse;
          var xhr = req.ptr;
          xhr.abort();
          xhr.onreadystatechange = function() {};
          req.ptr = (typeof(ActiveXObject) == 'undefined') ? new(XMLHttpRequest)() : new(ActiveXObject)('MSXML2.XMLHTTP');
          rb_funcall(req, id_fire, 2, sym_cancel, Qnil);
        }
        return req;
      }
    END
  end
  
  # 
  def req_execute
    add_function :rb_obj_alloc, :rb_process_scripts, :rb_funcall, :rb_req_parameters
    add_method :fire
    <<-END
      function req_execute(req) {
        req.running = Qtrue;
        var xhr = req.ptr;
        
        rb_req_parameters(req, {});
        
        xhr.open(req.method, req.url, req.async);
        xhr.onreadystatechange = function() {
          var xhr = this;
          if ((xhr.readyState != 4) || !(req.running)) { return; }
          req.running = Qfalse;
          try { req.status = xhr.status } catch (e) {}
          var resp = req.response = rb_obj_alloc(rb_cResponse);
          if ((req.status >= 200) && (req.status < 300)) {
            resp.text = rb_process_scripts(xhr, req.eval_response, req.eval_scripts);
            resp.xml = xhr.responseXml || '';
            rb_funcall(req, id_fire, 2, sym_response, resp);
            rb_funcall(req, id_fire, 2, sym_success, resp);
          } else {
            resp.text = '';
            resp.xml = '';
            rb_funcall(req, id_fire, 2, sym_response, resp);
            rb_funcall(req, id_fire, 2, sym_failure, resp);
          }
          xhr.onreadystatechange = function() {};
        };
        
        var headers = req.headers;
        for (var x in headers) { xhr.setRequestHeader(x, headers[x]); }
        
        rb_funcall(req, id_fire, 2, sym_request);
        xhr.send(req.data || '');
        if (!req.async) { xhr.onreadystatechange() }
        return req;
      }
    END
  end
  
  # 
  def req_initialize
    add_function :rb_scan_args, :rb_check_type, :rb_req_parameters
    <<-END
      function req_initialize(argc, argv, req) {
        var opts_tbl;
        var tmp = rb_scan_args(argc, argv, '01');
        if (tmp[0]) {
          Check_Type(tmp[1], T_HASH);
          opts_tbl = tmp[1].tbl;
        } else {
          opts_tbl = {};
        }
        req.ptr = (typeof(ActiveXObject) == 'undefined') ? new(XMLHttpRequest)() : new(ActiveXObject)('MSXML2.XMLHTTP');
        req.url = '';
        req.data = 0;
        req.async = Qtrue;
        req.response = Qnil;
        req.method = 'POST';
        req.status = 0;
        req.format = '';
        req.running = Qfalse;
        req.encoding = 'utf-8';
        req.eval_scripts = false;
        req.eval_response = false;
        req.headers = {
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'text/javascript, text/html, application/xml, text/xml, */*'
        };
        rb_req_parameters(req, opts_tbl);
      }
    END
  end
  
  # complete
  def req_response
    <<-END
      function req_response(req) {
        return req.response;
      }
    END
  end
end
