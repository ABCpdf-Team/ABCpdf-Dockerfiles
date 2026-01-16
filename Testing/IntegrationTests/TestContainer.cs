using DotNet.Testcontainers.Builders;
using DotNet.Testcontainers.Containers;
using DotNet.Testcontainers.Images;
using Microsoft.Extensions.Logging;

namespace IntegrationTests;

public sealed class TestContainer
{
	private IContainer? _container;
	public async Task StartAsync(CancellationToken cancellationToken = default)
	{
		using var outputConsumer = Consume.RedirectStdoutAndStderrToConsole();
		_container = new ContainerBuilder(GetEnvVar("TEST_APP_IMAGE_TAG"))
			.WithOutputConsumer(outputConsumer)
			.WithWaitStrategy(
				Wait.ForUnixContainer()
					.UntilMessageIsLogged("Content root path: /app", 
						o => o.WithTimeout(TimeSpan.FromMinutes(1)))
			)
			.WithNetwork(new NetworkBuilder().Build())
			.WithPortBinding(8080, true)
			.WithPortBinding(8081, true)
			.WithEnvironment("ABCPDF_LICENSE_KEY", GetEnvVar("ABCPDF_LICENSE_KEY"))
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

	private static string GetEnvVar(string envVarName)
	{
		var value = Environment.GetEnvironmentVariable(envVarName);
		return !string.IsNullOrWhiteSpace(value) ? value : throw new InvalidOperationException($"{envVarName} env var must be set.");
	}
}