#if ABCPDF_13
using WebSupergoo.ABCpdf13;
#else
using WebSupergoo.ABCpdf14;
#endif

Console.WriteLine($"Starting PDF generation test application on .NET {Environment.OSVersion}...");
Console.WriteLine($".NET version: {Environment.Version}");
Console.WriteLine($"ABCpdf version: {XSettings.Version}");

var abcPdfLicense = Environment.GetEnvironmentVariable("ABCPDF_LICENSE_KEY") ??
	throw new InvalidOperationException("ABCpdf license key is not configured. Please set the license key in the 'ABCPDF_LICENSE_KEY' environment variable or user-secret.");
if (!XSettings.InstallLicense(abcPdfLicense))
{
    throw new InvalidOperationException("ABCpdf license failed installation. Please verify that the configured license key is valid.");
}

const string htmlFilePath = "simple.html";

try{
    // Test with default Chome engine
    await TestABCChrome(htmlFilePath);

#if ABCPDF_14
    await TestABCChrome(htmlFilePath, EngineType.Chrome123);
#endif
}
catch (Exception ex)
{
    Console.WriteLine($"Error generating PDF: {ex.Message} {ex}");
    return -99;
}

Console.WriteLine("PDF generation test application completed successfully.");

return 0;

static async Task TestABCChrome(string htmlFilePath, EngineType? engineType = null)
{
    using Doc doc = new();
    if(engineType is not null)
    {
        doc.HtmlOptions.Engine = engineType.Value;
    }
    var testDescription = $"Testing with {Environment.Version} using {XSettings.Version} with {doc.HtmlOptions.Engine}";
    Console.WriteLine($"Using ABCChrome version: {doc.HtmlOptions.Engine}");
    doc.AddImageHtml(await new StreamReader(htmlFilePath).ReadToEndAsync());
    doc.Save("output.pdf");
    if (File.Exists("output.pdf"))
    {
        Console.WriteLine($"PDF creation: {testDescription} succeded.");
    }
    else {
        throw new Exception($"{testDescription}");
    }
}