using WebSupergoo.ABCpdf13;

var builder = WebApplication.CreateBuilder(args);

// Set the ABCpdf license from dotnet secrets
var abcPdfLicense = builder.Configuration["ABCPDF_LICENSE_KEY"] ??
	throw new InvalidOperationException("ABCpdf license key is not configured. Please set the license key in the 'ABCPDF_LICENSE_KEY' environment variable or user-secret.");
if(!XSettings.InstallLicense(abcPdfLicense)) {
	throw new InvalidOperationException("ABCpdf license failed installation. Please verify that the configured license key is valid.");
}

builder.Services.AddHealthChecks();

var app = builder.Build();
app.MapHealthChecks("/healthz");

app.UseHttpsRedirection();

app.MapPost("htmlfiletopdf", async (IFormFile htmlFile) =>
{
	if (htmlFile.Length <= 0) return Results.BadRequest("No file uploaded.");
	using Doc doc = new();
	doc.AddImageHtml(await new StreamReader(htmlFile.OpenReadStream()).ReadToEndAsync());
	return Results.File(doc.GetData(), contentType: "application/pdf", fileDownloadName: $"{htmlFile.FileName}.pdf");
})
.WithName("HtmlFileToPdf")
.WithDescription("Renders the submitted HTML file to a pdf file.")
.Produces<byte[]>(StatusCodes.Status200OK, "application/pdf")
.DisableAntiforgery();

app.Run();