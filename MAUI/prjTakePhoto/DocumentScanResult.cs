using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace prjTakePhoto;

public sealed class DocumentScanResult
{
    public List<Uri> Images { get; set; } = new();
}
