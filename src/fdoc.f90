module fdoc
  implicit none
  private

  public :: say_hello
contains
  subroutine say_hello
    print *, "Hello, fdoc!"
  end subroutine say_hello
end module fdoc
