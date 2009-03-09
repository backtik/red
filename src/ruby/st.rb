class Red::MethodCompiler
  # verbatim
  def delete_never
    <<-END
      function delete_never(key, value, never) {
        if (value == never) { return ST_DELETE; }
        return ST_CONTINUE;
      }
    END
  end
  
  # 
  def new_size
    <<-END
      function new_size(size) {
        for (var i = 0, newsize = 8, l = 29; i < l; i++, newsize <<= 1) {
          if (newsize > size) { return primes[i]; }
        }
        return -1;
      }
    END
  end
  
  # 
  def st_add_direct
    <<-END
      function st_add_direct(table, key, value) {
        var hash_val = do_hash(key, table);
        var bin_pos = hash_val % table.num_bins;
        ADD_DIRECT(table, key, value, hash_val, bin_pos);
      }
    END
  end
  
  # verbatim
  def st_cleanup_safe
    add_function :st_foreach, :delete_never
    <<-END
      function st_cleanup_safe(table, never) {
        var num_entries = table.num_entries;
        st_foreach(table, delete_never, never);
        table.num_entries = num_entries;
      }
    END
  end
  
  # modified to return [result, value] instead of using pointers
  def st_delete_safe
    <<-END
      function st_delete_safe(table, key, value, never) {
        var result = 0;
        var hash_val = do_hash(key, table) % table.num_bins;
        var ptr = table.bins[hash_val];
        if ((ptr || 0) === 0) {
          if (value !== 0) { value = 0; }
          result = 0;
        }
        for(; (ptr || 0) !== 0; ptr = ptr.next) {
          if ((ptr.key != never) && ((ptr.key == key) || (table.type.compare(ptr.key, key) === 0))) {
            table.num_entries--;
            key = ptr.key;
            if (value !== 0) { value = ptr.record; }
            ptr.key = ptr.record = never;
            result = 1;
          }
        }
        return [result, value];
      }
    END
  end
  
  # verbatim
  def st_foreach
    <<-END
      function st_foreach(table, func, arg) {
        for (var i = 0; i < table.num_bins; i++) {
          var last = 0;
          for (var ptr = table.bins[i] || 0; ptr !== 0;) {
            var tmp;
            var retval = func(ptr.key, ptr.record, arg);
            switch (retval) {
              case ST_CHECK: /* check if hash is modified during iteration */
                tmp = 0;
                if (i < table.num_bins) {
                  for (tmp = table.bins[i]; tmp; tmp = tmp.next) {
                    if (tmp == ptr) break;
                  }
                }
                if (!tmp) {
                  /* call func with error notice */
                  return 1;
                }
                /* fall through */
              case ST_CONTINUE:
                last = ptr;
                ptr = ptr.next || 0;
                break;
              case ST_STOP:
                return 0;
              case ST_DELETE:
                tmp = ptr;
                if (last == 0) {
                  table.bins[i] = ptr.next || 0;
                } else {
                  last.next = ptr.next || 0;
                }
                ptr = ptr.next || 0;
                delete tmp;
                table.num_entries--;
            }
          }
        }
        return 0;
      }
    END
  end
  
  # replaced "free" with JS "delete"
  def st_free_table
    <<-END
      function st_free_table(table) {
        var ptr;
        var next;
        for (var i = 0, l = table.num_bins; i < l; ++i) {
          ptr = table.bins[i];
          while ((ptr || 0) !== 0) {
            next = ptr.next;
            delete(ptr);
            ptr = next;
          }
        }
        delete(table.bins);
        delete(table);
      }
    END
  end
  
  # verbatim
  def st_init_numtable
    add_function :st_init_table
    <<-END
      function st_init_numtable() {
        return st_init_table(type_numhash);
      }
    END
  end
  
  # verbatim
  def st_init_table
    add_function :st_init_table_with_size
    <<-END
      function st_init_table(type) {
        return st_init_table_with_size(type, 0);
      }
    END
  end
  
  # verbatim
  def st_init_table_with_size
    add_function :new_size
    <<-END
      function st_init_table_with_size(type, size) {
        size = new_size(size);
        var tbl = {};
        tbl.type = type;
        tbl.num_entries = 0;
        tbl.num_bins = size;
        tbl.bins = {};
        return tbl;
      }
    END
  end
  
  # verbatim
  def st_insert
    <<-END
      function st_insert(table, key, value) {
        var hash_val = do_hash(key, table);
        var bin_pos = hash_val % table.num_bins;
        var ptr = table.bins[bin_pos];
        if (((ptr || 0) !== 0) && ((ptr.hash != hash_val) || !((key == ptr.key) || (table.type.compare(key, ptr.key) === 0)))) {
          while (((ptr.next || 0) !== 0) && ((ptr.next.hash != hash_val) || !((key == ptr.next.key) || (table.type.compare(key, ptr.next.key) === 0)))) { ptr = ptr.next; }
          ptr = ptr.next;
        }
        if ((ptr || 0) === 0) {
          ADD_DIRECT(table, key, value, hash_val, bin_pos);
          return 0;
        } else {
          ptr.record = value;
          return 1;
        }
      }
    END
  end
  
  # modified to return array [result, value] instead of using pointers
  def st_lookup
    <<-END
      function st_lookup(table, key, value) {
        var result;
        var hash_val = do_hash(key, table);
        var bin_pos = hash_val % table.num_bins;
        var ptr = table.bins[bin_pos];
        if (((ptr || 0) !== 0) && ((ptr.hash != hash_val) || !((key == ptr.key) || (table.type.compare(key, ptr.key) === 0)))) {
          while (((ptr.next || 0) !== 0) && ((ptr.next.hash != hash_val) || !((key == ptr.next.key) || (table.type.compare(key, ptr.next.key) === 0)))) { ptr = ptr.next; }
          ptr = ptr.next;
        }
        if (ptr == 0) {
          result = 0;
        } else {
          if (value !== 0) { value = ptr.record; }
          result = 1;
        }
        return [result, value];
      }
    END
  end
end
