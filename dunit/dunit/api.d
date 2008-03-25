module dunit.api;

public import dunit.testfixture;
public import dunit.attribute;
public static import dunit.main;
public static import dunit.repository;

public void testAssemblyName(char[] name)
{
    dunit.repository.Repository.instance.testAssemblyName = name;
}
