<%@ Control Language="vb" AutoEventWireup="false" CodeBehind="HeaderUser.ascx.vb" Inherits="MngConsul.HeaderUser" %>





   <div class="header-right">

       <div class="header-action">
           🔔
       </div>

       <div class="header-user">
           <div class="user-avatar">PG</div>

           <div class="user-info">
               <div class="user-name">
                   <asp:Literal runat="server" ID="litUserName" Text="Pierre" />
               </div>
               <div class="user-role">Administrateur</div>
           </div>
       </div>

   </div>


<style> 

/* RIGHT */
.header-right{
    display:flex;
    align-items:center;
    gap:14px;
}

.header-action{
    width:42px;
    height:42px;
    border-radius:12px;
    border:1px solid var(--border);
    display:flex;
    align-items:center;
    justify-content:center;
    background:white;
    cursor:pointer;
}

.header-user{
    display:flex;
    align-items:center;
    gap:10px;
    background:white;
    border:1px solid var(--border);
    border-radius:14px;
    padding:6px 10px;
}

.user-avatar{
    width:34px;
    height:34px;
    border-radius:10px;
    background:var(--primary-weak);
    color:var(--primary);
    display:flex;
    align-items:center;
    justify-content:center;
    font-weight:800;
}

.user-name{
    font-size:14px;
    font-weight:700;
}

.user-role{
    font-size:11px;
    color:var(--muted);
}

@media(max-width:768px){
     .user-info{ 
         display:none; 

     } 
}
</style>
