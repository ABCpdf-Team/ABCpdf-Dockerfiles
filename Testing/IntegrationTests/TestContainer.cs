using DotNet.Testcontainers.Builders;
using DotNet.Testcontainers.Configurations;
using DotNet.Testcontainers.Containers;
using Microsoft.Extensions.Logging;

namespace IntegrationTests;

public sealed class TestContainer
{

	private const string ImageName = "abcpdf-testcontainer";
	private IContainer? _container;
	// This is the image tag of the abcpdf runtime docker image under test: e.g. " abcpdf/mcr-aspnet:10.0"
	// It is expected to be set as an environment variable in the test runner environment.
	private readonly string _baseImageRc = GetEnvVar("BASE_IMAGE_RC");
	private readonly string _abcpdfLicense = GetEnvVar("ABCPDF_LICENSE_KEY");
	public async Task StartAsync(CancellationToken cancellationToken = default)
	{
		var loggerFactory = LoggerFactory.Create(builder =>
		{
			builder
				.SetMinimumLevel(LogLevel.Debug)
				.AddConsole();
		});

		var appDir = Path.Combine(CommonDirectoryPath.GetProjectDirectory().DirectoryPath);
		var image = new ImageFromDockerfileBuilder()
			.WithBuildArgument("RESOURCE_REAPER_SESSION_ID", ResourceReaper.DefaultSessionId.ToString("D"))
			.WithBuildArgument("BASE_IMAGE_RC", _baseImageRc)
			.WithBuildArgument("BUILD_CONFIGURATION", "Release")
			.WithDockerfileDirectory(appDir)
			.WithContextDirectory(CommonDirectoryPath.GetSolutionDirectory().DirectoryPath)
			.WithName(ImageName)
			.WithLogger(loggerFactory.CreateLogger("ImageFromDockerfileBuilder"))
			.WithCleanUp(false)
			.Build();
		await image.CreateAsync(cancellationToken).ConfigureAwait(false);
		var network = new NetworkBuilder().Build();
			
		using var outputConsumer = Consume.RedirectStdoutAndStderrToConsole();

		_container = new ContainerBuilder(image.FullName)
			.WithName("abcpdf_test_app_container")
			.WithOutputConsumer(outputConsumer)
			.WithWaitStrategy(
				Wait.ForUnixContainer()
					.UntilMessageIsLogged("Content root path: /app", 
						o => o.WithTimeout(TimeSpan.FromMinutes(1)))
			)
			.WithNetwork(network)
			.WithPortBinding(8080, true)
			.WithPortBinding(8081, true)
			.WithEnvironment("ABCPDF_LICENSE_KEY", _abcpdfLicense)
			.Build();

		await _container.StartAsync(cancellationToken).ConfigureAwait(false);
		if (_container.State != TestcontainersStates.Running)
		{
			throw new ApplicationException("Failed to start test application container.");
		}
	}
	public Uri ConstructUri(string subPath)
	{
		if (_container != null)
			return new UriBuilder(
				Uri.UriSchemeHttp, _container.Hostname, _container.GetMappedPublicPort(8080), subPath).Uri;
		throw new InvalidOperationException("_container is not initialized");
	}

	public string GetTestFilesFolder() => Path.Combine(CommonDirectoryPath.GetSolutionDirectory().DirectoryPath, "TestFiles");

	private static string GetEnvVar(string EnvVarName)
	{
		var value = Environment.GetEnvironmentVariable(EnvVarName);
		return string.IsNullOrWhiteSpace(value) ? throw new InvalidOperationException($"{EnvVarName} env var must be set.") : value;
	}
}