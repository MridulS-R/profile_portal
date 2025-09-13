if defined?(Clamby)
  Clamby.configure({
    check: true,
    daemonize: true,
    error_clamscan_missing: false,
    error_file_missing: true,
    error_file_virus: true,
    output_level: 'low'
  })
end

