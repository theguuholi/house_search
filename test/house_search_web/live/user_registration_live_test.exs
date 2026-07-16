defmodule HouseSearchWeb.UserRegistrationLiveTest do
  use HouseSearchWeb.ConnCase, async: true

  describe "Registration page" do
    test "is unavailable for invite-only access", %{conn: conn} do
      conn = get(conn, "/users/register")

      assert html_response(conn, 404) =~ "Not Found"
    end
  end
end
