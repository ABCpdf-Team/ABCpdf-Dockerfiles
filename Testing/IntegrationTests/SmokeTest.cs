
using Xunit.Sdk;

namespace IntegrationTests;

public class SmokeTest :IClassFixture<TestContainer> {
		
	private readonly TestContainer _testContainer;

	public SmokeTest(TestContainer testContainer)
	{
		_testContainer = testContainer;
		Task.Run(async () => await _testContainer.StartAsync()).Wait();
	}

	[Fact]
	public async Task Test_container_should_start_correctly()
	{
		// Arrange
		var uri = _testContainer.ConstructUri("healthz");
		using var httpClient = new HttpClient();

		// Act
		var response = await httpClient.GetAsync(uri);

		// Assert
		Assert.Equal(System.Net.HttpStatusCode.OK, response.StatusCode);
	}
}