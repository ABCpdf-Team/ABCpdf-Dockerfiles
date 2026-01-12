using WebSupergoo.ABCpdf13;

var builder = WebApplication.CreateBuilder(args);

// Set the license from dotnet secrets



var abcPdfLicense = builder.Configuration["ABCPDF_LICENCE_KEY"];
//	throw new InvalidOperationException("ABCpdf license key is not configured. Please configure the 'ABCpdf:LicenseKey' secret or environment variable.");
if(!XSettings.InstallLicense(abcPdfLicense)) {
	throw new InvalidOperationException("ABCpdf license failed installation. Please verify that the configured license key is valid.");
}
builder.Services.AddHealthChecks();

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

app.MapHealthChecks("/healthz");

// Configure the HTTP request pipeline.
if(app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwaggerUI(options => {
	    options.SwaggerEndpoint("/openapi/v1.json", "v1");
    });
}

app.UseHttpsRedirection();

app.MapGet("/htmltopdf", (string htmlOrUrl) =>
{
	using Doc doc = new();
	if(htmlOrUrl.StartsWith("http"))
		doc.AddImageUrl(htmlOrUrl);
	else
		doc.AddImageHtml(htmlOrUrl);
	return Results.File(doc.GetData(), contentType: "application/pdf", fileDownloadName: "mypage.pdf");
})
.WithName("ConvertToHtml")
.WithDescription("Renders the submitted HTML or URL into a PDF file.")
.Produces<byte[]>(StatusCodes.Status200OK, "application/pdf");

app.Run();
