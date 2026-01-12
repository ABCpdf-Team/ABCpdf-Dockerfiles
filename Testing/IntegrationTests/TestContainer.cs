using DotNet.Testcontainers.Builders;
using DotNet.Testcontainers.Configurations;
using DotNet.Testcontainers.Containers;
using Microsoft.Extensions.Logging;

namespace IntegrationTests;

public sealed class TestContainer
{

	private const string ImageName = "abcpdf-api-testcontainer";
	private IContainer? _container;
		
	public async Task StartAsync(CancellationToken cancellationToken = default)
	{
		var baseImageRc = Environment.GetEnvironmentVariable("BASE_IMAGE_RC");
		var loggerFactory = LoggerFactory.Create(builder =>
		{
			builder
				.SetMinimumLevel(LogLevel.Debug)
				.AddConsole();
		});
			
		var appDir = Path.Combine(CommonDirectoryPath.GetProjectDirectory().DirectoryPath);
		var image = new ImageFromDockerfileBuilder()
			.WithBuildArgument("RESOURCE_REAPER_SESSION_ID", ResourceReaper.DefaultSessionId.ToString("D"))
			.WithBuildArgument("BASE_IMAGE_RC", baseImageRc)
			.WithBuildArgument("BUILD_CONFIGURATION", "Release")
			.WithDockerfileDirectory(appDir)
			.WithContextDirectory(CommonDirectoryPath.GetSolutionDirectory().DirectoryPath)
			.WithName(ImageName)
			.WithLogger(loggerFactory.CreateLogger("ImageFromDockerfileBuilder"))
			.Build();

		await image.CreateAsync(cancellationToken).ConfigureAwait(false);
		var network = new NetworkBuilder().Build();
			
		using IOutputConsumer outputConsumer = Consume.RedirectStdoutAndStderrToConsole();

		_container = new ContainerBuilder(ImageName)
			.WithOutputConsumer(outputConsumer)
			.WithWaitStrategy(
				Wait.ForUnixContainer()
					.UntilMessageIsLogged("Content root path: /app", 
						o => o.WithTimeout(TimeSpan.FromMinutes(1)))
			)
			.WithNetwork(network)
			.WithPortBinding(8080, true)
			.WithPortBinding(8081, true)
			.WithEnvironment("ABCPDF_LICENCE_KEY", Environment.GetEnvironmentVariable("ABCPDF_LICENCE_KEY"))
			.Build();
		await _container.StartAsync(cancellationToken).ConfigureAwait(false);
	}
	public Uri ConstructUri(string subPath)
	{
		if (_container != null)
			return new UriBuilder(
				Uri.UriSchemeHttp, _container.Hostname, _container.GetMappedPublicPort(8080), subPath).Uri;
		throw new InvalidOperationException("_container is not initialized");
	}
}