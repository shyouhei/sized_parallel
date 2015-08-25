This library lets you have a bunch of inter-dependent tasks run in parallel, but not all together.  Much like `make -j4` runs at most 4 tasks at once.

### Detailed usage

This library has only one intuitive usage.  First create a `SizedParallel` instance.

    sp = SizedParallel.new 65535

Omit the argument to use the active CPU count (default).

Then add your series of jobs.

    128.times {
      sp.start {
          Resolv.getaddress 'www.ruby-lang.org'
      }.then { |addr|
          Net::HTTP.get addr, '/'
      }.then { |html|
          Nokogiri::HTML html
      }
    }

In the example above 128 concurrent name resolution are registered.  Then for each resolved address, HTTP query is registered (in parallel).  And lastly the response HTML is registered to parse (also in parallel).

Those jobs are not triggered yet.  In order to do so you call a wait for the object.

    sp.wait

This blocks, until all the registered jobs finish either gracefully or unexpectedly.

### Restrictions

This library is written in pure ruby so ultra portable by nature, but requires at least version 2.2 or higher (or compatible alternatives) because Etc.nproessors is mandatory.
