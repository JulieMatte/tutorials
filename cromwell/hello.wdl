task hello {
  String name

  command {
    echo 'Hello ${name}!'
  }
  runtime {
    docker: 'ubuntu:latest'
    cpu : 2
    memory: '2 GB'
  }
  output {
    File response = stdout()
  }
}

workflow test {
  call hello
}
