#if ABCPDF_13
using WebSupergoo.ABCpdf13;
#else
using WebSupergoo.ABCpdf14;
#endif

Console.WriteLine($"Starting PDF generation test application on .NET {Environment.OSVersion}...");
Console.WriteLine($".NET version: {Environment.Version}");
Console.WriteLine($"Current ABCpdf version: {XSettings.Version}");

var abcPdfLicense = Environment.GetEnvironmentVariable("ABCPDF_LICENSE_KEY") ??
	throw new InvalidOperationException("ABCpdf license key is not configured. Please set the license key in the 'ABCPDF_LICENSE_KEY' environment variable or user-secret.");
if (!XSettings.InstallLicense(abcPdfLicense))
{
    throw new InvalidOperationException("ABCpdf license failed installation. Please verify that the configured license key is valid.");
}

const string htmlFilePath = "simple.html";

try{
    using Doc doc = new();
    doc.HtmlOptions.Engine = EngineType.Chrome123;
    Console.WriteLine($"Current ABCChrome version: {doc.HtmlOptions.Engine}");
    doc.AddImageHtml(await new StreamReader(htmlFilePath).ReadToEndAsync());
    doc.Save("output.pdf");
}
catch (Exception ex)
{
    Console.WriteLine($"Error generating PDF: {ex}");
    return -99;
}

Console.WriteLine("PDF generation test application completed successfully.");

return 0;