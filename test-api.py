import requests
import json

#API_ENDPOINT = "{API Gateway endpoint url}/{stage}"
API_ENDPOINT = "https://538mytpeo3.execute-api.us-east-1.amazonaws.com/dev"

def test_api():
    response = requests.get(API_ENDPOINT + "/info")
    #assert response.status_code == 200 #for testing
    data = response.json()
    print(json.dumps(data, indent=2))

if __name__ == "__main__":
    test_api()
