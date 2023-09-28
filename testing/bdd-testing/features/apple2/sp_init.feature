Feature: library test - apple2 spn_init

  This tests fujinet-network apple2 spn_init

  Scenario: execute sp.c
    Given apple2-fn-nw application test setup
      And I add common apple2-sp files
      And I add file for compiling "features/apple2/invokers/test_sp_init.s"
      And I create and load apple-single application
     When I execute the procedure at _init for no more than 100 instructions

     # return from _spn_init is 1 in A, and 0 in X
     And I expect register A equal 1
     And I expect register X equal 0
