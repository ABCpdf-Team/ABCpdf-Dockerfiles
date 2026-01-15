using DotNet.Testcontainers.Builders;
using DotNet.Testcontainers.Containers;
using DotNet.Testcontainers.Images;
using Microsoft.Extensions.Logging;

namespace IntegrationTests;

public sealed class TestContainer
{
	// This is the image tag of the abcpdf runtime docker image under test: e.g. " abcpdf/mcr-aspnet:10.0"
	// It is expected to be set as an environment variable in the test runner environment.
	private readonly string _baseImageRc = GetEnvVar("BASE_IMAGE_RC");
	private readonly string _abcpdfLicense = GetEnvVar("ABCPDF_LICENSE_KEY");
	private readonly string _dotnetVersion = GetEnvVar("DOTNET_VERSION");
	private IFutureDockerImage _image;
	private IContainer? _container;

	public async Task StartAsync(CancellationToken cancellationToken = default)
	{
		await BuildAsync(cancellationToken);

		using var outputConsumer = Consume.RedirectStdoutAndStderrToConsole();

		_container = new ContainerBuilder(_image.FullName)
			.WithName("abcpdf_test_app_container")
			.WithOutputConsumer(outputConsumer)
			.WithWaitStrategy(
				Wait.ForUnixContainer()
					.UntilMessageIsLogged("Content root path: /app", 
						o => o.WithTimeout(TimeSpan.FromMinutes(1)))
			)
			.WithNetwork(new NetworkBuilder().Build())
			.WithPortBinding(8080, true)
			.WithPortBinding(8081, true)
			.WithEnvironment("ABCPDF_LICENSE_KEY", _abcpdfLicense)
			.WithEnvironment("DOTNET_VERSION", _dotnetVersion)
			.Build();

		await _container.StartAsync(cancellationToken).ConfigureAwait(false);
		if (_container.State != TestcontainersStates.Running)
		{
			throw new ApplicationException("Failed to start test application container.");
		}
	}

	private async Task BuildAsync(CancellationToken cancellationToken)
	{
		var loggerFactory = LoggerFactory.Create(builder =>
		{
			builder
				.SetMinimumLevel(LogLevel.Debug)
				.AddConsole();
		});

		var imageName = $"abcpdf-testcontainer{_dotnetVersion}";

		var appDir = Path.Combine(CommonDirectoryPath.GetProjectDirectory().DirectoryPath);
		_image = new ImageFromDockerfileBuilder()
			.WithBuildArgument("RESOURCE_REAPER_SESSION_ID", ResourceReaper.DefaultSessionId.ToString("D"))
			.WithBuildArgument("TARGET_FRAMEWORK", $"net{_dotnetVersion}")
			.WithBuildArgument("BASE_IMAGE_RC", _baseImageRc)
			.WithBuildArgument("BUILD_CONFIGURATION", "Release")
			.WithDockerfileDirectory(appDir)
			.WithContextDirectory(CommonDirectoryPath.GetSolutionDirectory().DirectoryPath)
			.WithName(imageName)
			.WithLogger(loggerFactory.CreateLogger("ImageFromDockerfileBuilder"))
			.WithCleanUp(false)
			.Build();
		await _image.CreateAsync(cancellationToken).ConfigureAwait(false);
	}

	public Uri ConstructUri(string subPath)
	{
		if (_container != null)
			return new UriBuilder(
				Uri.UriSchemeHttp, _container.Hostname, _container.GetMappedPublicPort(8080), subPath).Uri;
		throw new InvalidOperationException("_container is not initialized");
	}

	public string GetTestFilesFolder() => Path.Combine(CommonDirectoryPath.GetSolutionDirectory().DirectoryPath, "TestFiles");

	private static string GetEnvVar(string envVarName)
	{
		var value = Environment.GetEnvironmentVariable(envVarName);
		return !string.IsNullOrWhiteSpace(value) ? value : throw new InvalidOperationException($"{envVarName} env var must be set.");
	}
}