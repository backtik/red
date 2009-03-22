puts [
  Time.now.equal?(Time.now),
  Time.now == Time.now,
  Time.now.eql?(Time.now),
  Time.now === Time.now
]
