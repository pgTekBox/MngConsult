using Microsoft.Data.SqlClient;

using System.Data;
using Newtonsoft.Json; 

namespace APIWebMngConsul
{
    public class DatabaseHelper
    {
     string ConnectionString = "Server=192.168.0.203;Database=MngConsul;User Id=UserMngConsul;Password=pw4MngConsul;TrustServerCertificate=true;";

        public System.Data.DataSet GetDataSet(string StoreProc )
        {
           

            SqlConnection myConnection = new SqlConnection(ConnectionString);
            SqlCommand myCommand;
            myCommand = new SqlCommand(StoreProc, myConnection);
            myCommand.CommandType = System.Data.CommandType.StoredProcedure;
           
            myConnection.Open();
            SqlDataAdapter adapter = new SqlDataAdapter(myCommand);
            adapter.SelectCommand.CommandTimeout = 60;
            // Fill the dataset
            DataSet dsData = new DataSet();
            adapter.Fill(dsData);
            myConnection.Close();
            return dsData;
        }
        public System.Data.DataSet GetDataSet(string StoreProc, Dictionary<string, object> Param  )
        {
            if (Param == null)
                Param = new Dictionary<string, object>();

            SqlConnection myConnection = new  SqlConnection(ConnectionString);
            SqlCommand myCommand;
            myCommand = new SqlCommand(StoreProc, myConnection);
            myCommand.CommandType = System.Data.CommandType.StoredProcedure;
            foreach (KeyValuePair<string, object> item in Param)
            {
                if (item.Value is DataTable)
                {
                    SqlParameter MyParam = myCommand.Parameters.AddWithValue(item.Key, item.Value);
                    MyParam.SqlDbType = SqlDbType.Structured;
                    MyParam.TypeName = "dbo.KeyValues";
                }
                else
                    myCommand.Parameters.AddWithValue(item.Key, item.Value);
            }
            myConnection.Open();
            SqlDataAdapter adapter = new SqlDataAdapter(myCommand);
            adapter.SelectCommand.CommandTimeout = 60;
            // Fill the dataset
            DataSet dsData = new DataSet();
            adapter.Fill(dsData);
            myConnection.Close();
            return dsData;
        }
       

    public string DataTableToJSONWithJSONNet(DataTable table)
    {
        string JSONString = string.Empty;
        JSONString =  JsonConvert.SerializeObject(table);
            //JsonConvert.DeserializeObject() 
        return JSONString;
    }


    //    public DataTable ExecuteStringSP(string StoreProc, Dictionary<string, object> Param = null)
    //    {
    //        if (Param == null)
    //            Param = new Dictionary<string, object>();

    //        SqlClient.SqlConnection myConnection = new SqlClient.SqlConnection(ConnectionString);
    //        SqlClient.SqlCommand myCommand;
    //        myCommand = new SqlClient.SqlCommand(StoreProc, myConnection);
    //        myCommand.CommandType = System.Data.CommandType.StoredProcedure;
    //        foreach (KeyValuePair<string, object> item in Param)
    //            myCommand.Parameters.AddWithValue(item.Key, item.Value);
    //        myConnection.Open();
    //        SqlDataAdapter adapter = new SqlDataAdapter(myCommand);
    //        adapter.SelectCommand.CommandTimeout = CommandeTimeOut;
    //        // Fill the dataset
    //        DataSet dsData = new DataSet();
    //        adapter.Fill(dsData);
    //        myConnection.Close();
    //        if (dsData.Tables.Count > 0)
    //        {
    //            DataTable dt = dsData.Tables(0);
    //            dsData.Tables.Remove(dt);
    //            return dt;
    //        }
    //        return null/* TODO Change to default(_) if this is not a reference type */;
    //    }

    public object ExecuteScalarStringSP(string StoreProc, Dictionary<string, object> Param  )
        {
            if (Param == null)
                Param = new Dictionary<string, object>();

             SqlConnection myConnection = new  SqlConnection(ConnectionString);
             SqlCommand myCommand;
            myCommand = new  SqlCommand(StoreProc, myConnection);
            myCommand.CommandType = System.Data.CommandType.StoredProcedure;
            myCommand.CommandTimeout = 60;
            foreach (KeyValuePair<string, object> item in Param)
                myCommand.Parameters.AddWithValue(item.Key, item.Value);
            myConnection.Open();
            object output;
            try
            {
                  output = myCommand.ExecuteScalar();
                 
            }
            finally
            {
                myConnection.Close();
            }
            return output;
        }

        //    public object ExecuteSqlStringScalar(string sqlString)
        //    {
        //        SqlClient.SqlConnection myConnection = new SqlClient.SqlConnection(ConnectionString);
        //        SqlClient.SqlCommand myCommand;
        //        myCommand = new SqlClient.SqlCommand(sqlString, myConnection);
        //        myCommand.CommandType = System.Data.CommandType.Text;
        //        myCommand.CommandTimeout = CommandeTimeOut;
        //        myConnection.Open();
        //        object retval = myCommand.ExecuteScalar();
        //        myConnection.Close();
        //        return retval;
        //    }

        //    public DataSet ExecuteSqlString(string sqlString)
        //    {
        //        SqlClient.SqlDataAdapter oDa = new SqlClient.SqlDataAdapter(sqlString, ConnectionString);
        //        oDa.SelectCommand.CommandTimeout = CommandeTimeOut;
        //        DataSet oDs = new DataSet();
        //        oDa.Fill(oDs);
        //        return oDs;
        //    }

        //    public void ExecuteSPCommand(SqlClient.SqlCommand myCommand)
        //    {
        //        SqlClient.SqlConnection myConnection = new SqlClient.SqlConnection(ConnectionString);
        //        myCommand.Connection = myConnection;
        //        myCommand.CommandType = CommandType.StoredProcedure;
        //        myCommand.CommandTimeout = CommandeTimeOut;
        //        myConnection.Open();
        //        myCommand.ExecuteNonQuery();
        //        myConnection.Close();
        //    }

        //    public void ExecuteNonQueryStringSP(string StoreProc, Dictionary<string, object> Param = null)
        //    {
        //        if (Param == null)
        //            Param = new Dictionary<string, object>();

        //        SqlClient.SqlConnection myConnection = new SqlClient.SqlConnection(ConnectionString);
        //        SqlClient.SqlCommand myCommand;
        //        myCommand = new SqlClient.SqlCommand(StoreProc, myConnection);
        //        myCommand.CommandType = System.Data.CommandType.StoredProcedure;
        //        foreach (KeyValuePair<string, object> item in Param)
        //            myCommand.Parameters.AddWithValue(item.Key, item.Value);
        //        myCommand.CommandTimeout = CommandeTimeOut;
        //        myConnection.Open();
        //        myCommand.ExecuteNonQuery();
        //        myConnection.Close();
        //    }

        //    public void ExecuteNonQuerySqlString(string sqlString)
        //    {
        //        SqlClient.SqlConnection myConnection = new SqlClient.SqlConnection(ConnectionString);

        //        SqlClient.SqlCommand myCommand;
        //        myCommand = new SqlClient.SqlCommand(sqlString, myConnection);
        //        myCommand.CommandType = System.Data.CommandType.Text;
        //        myCommand.CommandTimeout = CommandeTimeOut;
        //        myConnection.Open();
        //        myCommand.ExecuteNonQuery();
        //        myConnection.Close();
        //    }
        //}

    }


}
