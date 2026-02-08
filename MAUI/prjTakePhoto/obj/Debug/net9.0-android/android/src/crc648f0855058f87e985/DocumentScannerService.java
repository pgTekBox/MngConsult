package crc648f0855058f87e985;


public class DocumentScannerService
	extends java.lang.Object
	implements
		mono.android.IGCUserPeer
{
/** @hide */
	public static final String __md_methods;
	static {
		__md_methods = 
			"";
		mono.android.Runtime.register ("prjTakePhoto.Platforms.Android.DocumentScannerService, prjTakePhoto", DocumentScannerService.class, __md_methods);
	}

	public DocumentScannerService ()
	{
		super ();
		if (getClass () == DocumentScannerService.class) {
			mono.android.TypeManager.Activate ("prjTakePhoto.Platforms.Android.DocumentScannerService, prjTakePhoto", "", this, new java.lang.Object[] {  });
		}
	}

	private java.util.ArrayList refList;
	public void monodroidAddReference (java.lang.Object obj)
	{
		if (refList == null)
			refList = new java.util.ArrayList ();
		refList.add (obj);
	}

	public void monodroidClearReferences ()
	{
		if (refList != null)
			refList.clear ();
	}
}
