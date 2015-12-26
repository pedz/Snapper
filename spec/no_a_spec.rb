require "spec_helper"
require "no_a"

describe NoA do
  describe "#parse" do
    before(:context) {
      text = <<'EOF'

                 arpqsize = 1024
               arpt_killc = 20
              arptab_bsiz = 7
                arptab_nb = 149
                bcastping = 0
             bsd_loglevel = 3
      clean_partial_conns = 0
                 delayack = 0
            delayackports = {}
   dgd_flush_cached_route = 0
         dgd_packets_lost = 3
            dgd_ping_time = 5
           dgd_retry_time = 5
       directed_broadcast = 0
                 fasttimo = 200
                    hstcp = 0
        icmp6_errmsg_rate = 10
          icmpaddressmask = 0
ie5_old_multicast_mapping = 0
                   ifsize = 256
           igmpv2_deliver = 0
            init_high_wat = 0
               ip6_defttl = 64
                ip6_prune = 1
            ip6forwarding = 0
       ip6srcrouteforward = 1
       ip_ifdelete_notify = 0
                 ip_nfrag = 200
             ipforwarding = 0
                ipfragttl = 2
        ipignoreredirects = 0
                ipqmaxlen = 100
          ipsendredirects = 1
        ipsrcrouteforward = 1
           ipsrcrouterecv = 0
           ipsrcroutesend = 1
               limited_ss = 0
          llsleep_timeout = 3
                  lo_perf = 1
                lowthresh = 90
                 main_if6 = 0
               main_site6 = 0
                 maxnip6q = 20
                   maxttl = 255
                medthresh = 95
               mpr_policy = 1
              multi_homed = 1
                nbc_limit = 1048576
            nbc_max_cache = 131072
            nbc_min_cache = 1
         nbc_ofile_hashsz = 12841
                 nbc_pseg = 0
           nbc_pseg_limit = 2097152
           ndd_event_name = {all}
        ndd_event_tracing = 0
              ndogthreads = 0
            ndp_mmaxtries = 3
            ndp_umaxtries = 3
                 ndpqsize = 50
                ndpt_down = 3
                ndpt_keep = 120
               ndpt_probe = 5
           ndpt_reachable = 30
             ndpt_retrans = 1
             net_buf_size = {all}
             net_buf_type = {all}
     net_malloc_frag_mask = {512:2048}
        netm_page_promote = 1
           nonlocsrcroute = 0
                 nstrpush = 8
              passive_dgd = 0
         pmtu_default_age = 10
              pmtu_expire = 10
 pmtu_rediscover_interval = 30
              psebufcalls = 20
                 psecache = 1
                psetimers = 20
           rfc1122addrchk = 0
                  rfc1323 = 0
                  rfc2414 = 1
             route_expire = 1
          routerevalidate = 0
     rtentry_lock_complex = 0
                 rto_high = 64
               rto_length = 13
                rto_limit = 7
                  rto_low = 1
                     sack = 0
                   sb_max = 1048576
       send_file_duration = 300
              site6_index = 0
               sockthresh = 85
                  sodebug = 0
              sodebug_env = 0
                somaxconn = 1024
                 strctlsz = 1024
                 strmsgsz = 0
                strthresh = 85
               strturncnt = 15
          subnetsarelocal = 1
       tcp_bad_port_limit = 0
        tcp_cwnd_modified = 0
                  tcp_ecn = 0
       tcp_ephemeral_high = 65535
        tcp_ephemeral_low = 32768
               tcp_fastlo = 0
     tcp_fastlo_crosswpar = 0
             tcp_finwait2 = 1200
           tcp_icmpsecure = 0
          tcp_init_window = 0
    tcp_inpcb_hashtab_siz = 24499
              tcp_keepcnt = 8
             tcp_keepidle = 14400
             tcp_keepinit = 150
            tcp_keepintvl = 150
     tcp_limited_transmit = 1
              tcp_low_rto = 0
             tcp_maxburst = 0
              tcp_mssdflt = 1460
          tcp_nagle_limit = 65535
        tcp_nagleoverride = 0
               tcp_ndebug = 100
              tcp_newreno = 1
           tcp_nodelayack = 0
        tcp_pmtu_discover = 1
            tcp_recvspace = 16384
            tcp_sendspace = 16384
            tcp_tcpsecure = 0
             tcp_timewait = 1
                  tcp_ttl = 60
           tcprexmtthresh = 3
             tcptr_enable = 0
                  thewall = 4194304
         timer_wheel_tick = 0
                tn_filter = 1
       udp_bad_port_limit = 0
       udp_ephemeral_high = 65535
        udp_ephemeral_low = 32768
    udp_inpcb_hashtab_siz = 24499
        udp_pmtu_discover = 1
            udp_recvspace = 42080
            udp_sendspace = 9216
                  udp_ttl = 30
                 udpcksum = 1
           use_sndbufpool = 1

EOF
      @result = NoA.new(text, Hash.new).parse
    }
    
    it "parses and makes an entry for each value" do
      expect(@result.length).to eq(145)
    end
    
    it "converts integer values to Fixnums" do
      expect(@result['udp_inpcb_hashtab_siz']).to be_an_instance_of(Fixnum)
    end
    
    it "keeps other values as strings" do
      expect(@result['ndd_event_name']).to be_an_instance_of(String)
    end
    
    it "removes the new line from string values" do
      expect(@result['net_malloc_frag_mask']).to eq('{512:2048}')
    end
  end
end
