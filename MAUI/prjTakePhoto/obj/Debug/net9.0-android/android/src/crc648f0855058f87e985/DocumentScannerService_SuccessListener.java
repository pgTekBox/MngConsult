package crc648f0855058f87e985;


public class DocumentScannerService_SuccessListener
	extends java.lang.Object
	implements
		mono.android.IGCUserPeer,
		com.google.android.gms.tasks.OnSuccessListener
{
/** @hide */
	public static final String __md_methods;
	static {
		__md_methods = 
			"n_onSuccess:(Ljava/lang/Object;)V:GetOnSuccess_Ljava_lang_Object_Handler:Android.Gms.Tasks.IOnSuccessListenerInvoker, Xamarin.GooglePlayServices.Tasks\n" +
			"";
		mono.android.Runtime.register ("prjTakePhoto.Platforms.Android.DocumentScannerService+SuccessListener, prjTakePhoto", DocumentScannerService_SuccessListener.class, __md_methods);
	}

	public DocumentScannerService_SuccessListener ()
	{
		super ();
		if (getClass () == DocumentScannerService_SuccessListener.class) {
			mono.android.TypeManager.Activate ("prjTakePhoto.Platforms.Android.DocumentScannerService+SuccessListener, prjTakePhoto", "", this, new java.lang.Object[] {  });
		}
	}

	public void onSuccess (java.lang.Object p0)
	{
		n_onSuccess (p0);
	}

	private native void n_onSuccess (java.lang.Object p0);

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
