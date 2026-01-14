using DotNet.Testcontainers.Builders;
using System.Net.Http.Headers;

namespace IntegrationTests;

public class SmokeTests : IClassFixture<TestContainer> {
		
	private readonly TestContainer _testContainer;

	public SmokeTests(TestContainer testContainer)
	{
		_testContainer = testContainer;
		Task.Run(async () => await _testContainer.StartAsync()).Wait();
	}

	[Fact]
	public async Task Should_render_simple_html_file_correctly()
	{
		// Arrange
		var testfilename = "simple.html";
		var filePath = Path.Combine(_testContainer.GetTestFilesFolder(), testfilename);
		using var form = new MultipartFormDataContent();
		using var fileContent = new ByteArrayContent(await File.ReadAllBytesAsync(filePath));
		fileContent.Headers.ContentType = MediaTypeHeaderValue.Parse("text/html");
		form.Add(fileContent, "htmlFile", testfilename);

		var uri = _testContainer.ConstructUri("htmlfiletopdf");
		using var httpClient = new HttpClient();

		// Act
		var response = await httpClient.PostAsync(uri, form);

		// Assert
		Assert.Equal(System.Net.HttpStatusCode.OK, response.StatusCode);
		Assert.True(response.Content.Headers.ContentType?.MediaType == "application/pdf");
		Assert.True(response.Content.Headers.ContentLength > 0);
	}
	
	
}