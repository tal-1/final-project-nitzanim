terraform {
  backend "s3" {
    # leaving encrypt as true because its a static security best-practice
    encrypt        = true
  }
}
